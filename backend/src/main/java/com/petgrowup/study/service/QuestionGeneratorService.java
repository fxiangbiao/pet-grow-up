package com.petgrowup.study.service;

import com.petgrowup.study.dto.QuestionDTO;
import com.petgrowup.study.entity.QuizQuestion;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import com.mybatisflex.core.query.QueryWrapper;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static com.petgrowup.study.entity.table.QuizQuestionTableDef.QUIZ_QUESTION;

@Service
public class QuestionGeneratorService {

    /** 选择题选项 JSON 里单个选项的形状：{"key":"A","text":"..."} */
    private static final Pattern OPTION_PATTERN =
            Pattern.compile("\\{\\s*\"key\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"text\"\\s*:\\s*\"([^\"]*)\"\\s*\\}");

    /**
     * 变式题由前端在本地判分，只有这些题型的答案载荷前端能可靠比对：
     * 选择题/泡泡点击交选项 key，判断交 true|false，填空/数字输入交文本，
     * 诗句排序交索引串（如 "2,1,3,4"），单词配对交配对串（如 "1a,2b"）。
     * 其余 SCENE_* 由各自的场景组件按题号向后端提交，变式题没有题号，无法复用。
     */
    private static final Set<String> LOCALLY_ANSWERABLE_TYPES = Set.of(
            "MULTIPLE_CHOICE", "SCENE_TAP", "TRUE_FALSE", "FILL_BLANK",
            "MATH_INPUT", "POEM_SEQUENCE", "VOCAB_MATCH");

    private final QuizQuestionMapper questionMapper;

    public QuestionGeneratorService(QuizQuestionMapper questionMapper) {
        this.questionMapper = questionMapper;
    }

    /**
     * Generate a new question based on an existing question's template.
     * For math: replaces numbers with new random values within constraints.
     * For other subjects: picks a different question from the same node.
     */
    public Map<String, Object> generateVariant(Long knowledgeNodeId, Long originalQuestionId) {
        QuizQuestion original = questionMapper.selectOneById(originalQuestionId);
        if (original == null) {
            return null;
        }

        String questionText = original.getQuestionText();
        String correctAnswer = original.getCorrectAnswer();
        String questionType = original.getQuestionType();

        Map<String, Object> result = new HashMap<>();

        // Try to generate a math variant by replacing numbers
        if ("FILL_BLANK".equals(questionType) || "MULTIPLE_CHOICE".equals(questionType)) {
            List<Integer> numbers = extractNumbers(questionText);
            if (numbers.size() >= 2) {
                // Generate new numbers
                List<Integer> newNumbers = generateNewNumbers(numbers);
                String newQuestionText = replaceNumbers(questionText, numbers, newNumbers);
                String newAnswer = calculateAnswer(questionText, correctAnswer, numbers, newNumbers);

                // 选择题必须带上选项，且正确选项必须真的在这批选项里，否则退化成填空题
                String[] variantOptions = null;
                if ("MULTIPLE_CHOICE".equals(questionType)) {
                    variantOptions = buildVariantOptions(
                            original.getOptions(), numbers, newNumbers, newAnswer);
                }

                result.put("questionText", newQuestionText);
                if (variantOptions != null) {
                    // buildVariantOptions 已经把 correctAnswer 换算成选项 key
                    result.put("correctAnswer", variantOptions[1]);
                    result.put("questionType", "MULTIPLE_CHOICE");
                    result.put("options", variantOptions[0]);
                } else {
                    result.put("correctAnswer", newAnswer);
                    // 无法安全替换出可作答的选项时降级为填空题，绝不返回"没有选项的选择题"
                    result.put("questionType", "MULTIPLE_CHOICE".equals(questionType) ? "FILL_BLANK" : questionType);
                }
                result.put("originalQuestionId", originalQuestionId);
                result.put("originalText", questionText);
                result.put("isGenerated", true);
                return result;
            }
        }

        // Fallback: pick a different question from the same node
        List<QuizQuestion> alternatives = questionMapper.selectListByQuery(
                QueryWrapper.create()
                        .select(QUIZ_QUESTION.ID, QUIZ_QUESTION.QUESTION_TYPE,
                                QUIZ_QUESTION.QUESTION_TEXT, QUIZ_QUESTION.OPTIONS,
                                QUIZ_QUESTION.POINTS, QUIZ_QUESTION.CORRECT_ANSWER,
                                QUIZ_QUESTION.EXPLANATION, QUIZ_QUESTION.KNOWLEDGE_NODE_ID)
                        .where(QUIZ_QUESTION.KNOWLEDGE_NODE_ID.eq(knowledgeNodeId))
                        .and(QUIZ_QUESTION.ID.ne(originalQuestionId))
        );

        if (!alternatives.isEmpty()) {
            // 优先挑"孩子能在拓环节当场作答、且前端能本地判分"的题型。
            // 原因：变式题不在题库里、没有题号，而 SCENE_DRAG / SCENE_MATCH 等场景组件
            // 是自行按题号向后端提交答案的，走不了那条链路，挑到它们孩子只能干看着。
            List<QuizQuestion> answerable = alternatives.stream()
                    .filter(q -> LOCALLY_ANSWERABLE_TYPES.contains(q.getQuestionType()))
                    .collect(Collectors.toList());
            List<QuizQuestion> pool = answerable.isEmpty() ? alternatives : answerable;
            QuizQuestion alt = pool.get(new Random().nextInt(pool.size()));
            result.put("questionText", alt.getQuestionText());
            result.put("correctAnswer", alt.getCorrectAnswer());
            result.put("questionType", alt.getQuestionType());
            result.put("options", alt.getOptions());
            result.put("explanation", alt.getExplanation());
            result.put("originalQuestionId", originalQuestionId);
            result.put("originalText", questionText);
            result.put("isGenerated", false);
            return result;
        }

        // Last resort: return the original question
        result.put("questionText", questionText);
        result.put("correctAnswer", correctAnswer);
        result.put("questionType", questionType);
        result.put("options", original.getOptions());
        result.put("explanation", original.getExplanation());
        result.put("originalQuestionId", originalQuestionId);
        result.put("originalText", questionText);
        result.put("isGenerated", false);
        return result;
    }

    private List<Integer> extractNumbers(String text) {
        List<Integer> numbers = new ArrayList<>();
        Pattern p = Pattern.compile("\\d+");
        Matcher m = p.matcher(text);
        while (m.find()) {
            numbers.add(Integer.parseInt(m.group()));
        }
        return numbers;
    }

    private List<Integer> generateNewNumbers(List<Integer> originalNumbers) {
        Random rand = new Random();
        List<Integer> newNumbers = new ArrayList<>();
        for (int num : originalNumbers) {
            // Generate a new number within 卤3 of the original (min 1)
            int delta = rand.nextInt(7) - 3; // -3 to +3
            int newNum = Math.max(1, num + delta);
            newNumbers.add(newNum);
        }
        return newNumbers;
    }

    private String replaceNumbers(String text, List<Integer> oldNums, List<Integer> newNums) {
        String result = text;
        // Replace from largest to smallest to avoid partial replacements
        Integer[] indices = new Integer[oldNums.size()];
        for (int i = 0; i < indices.length; i++) indices[i] = i;
        Arrays.sort(indices, (a, b) -> oldNums.get(b).compareTo(oldNums.get(a)));

        for (int idx : indices) {
            result = result.replaceFirst(
                    "\\b" + oldNums.get(idx) + "\\b",
                    String.valueOf(newNums.get(idx))
            );
        }
        return result;
    }

    private String calculateAnswer(String originalText, String originalAnswer,
                                    List<Integer> oldNums, List<Integer> newNums) {
        // Simple pattern matching for basic arithmetic
        try {
            if (originalText.contains("+") && oldNums.size() >= 2) {
                int sum = newNums.get(0) + newNums.get(1);
                return String.valueOf(sum);
            } else if (originalText.contains("-") && oldNums.size() >= 2) {
                int diff = Math.abs(newNums.get(0) - newNums.get(1));
                return String.valueOf(diff);
            }
        } catch (Exception e) {
            // Fall through
        }
        return originalAnswer;
    }

    /**
     * 为变式选择题生成选项：把原题 options 里出现的数字用与 replaceNumbers 完全相同的新旧数字映射替换，
     * 并确认算出来的新答案确实落在这批替换后的选项里（否则这道选择题无解）。
     * 题干换数后 key 正确的选项可能已经不是原来的 key，所以这里用"答案值"反查选项 key。
     *
     * @return {替换后的 options JSON, 正确选项的 key}；无法安全生成时返回 null，调用方应降级为填空题
     */
    private String[] buildVariantOptions(String optionsJson, List<Integer> oldNums,
                                         List<Integer> newNums, String newAnswer) {
        if (optionsJson == null || optionsJson.isBlank() || newAnswer == null || newAnswer.isBlank()) {
            return null;
        }

        String replacedOptions = replaceNumbers(optionsJson, oldNums, newNums);

        Matcher m = OPTION_PATTERN.matcher(replacedOptions);
        String matchedKey = null;
        while (m.find()) {
            String key = m.group(1);
            String text = m.group(2);
            if (!answerMatchesOption(newAnswer, text)) {
                continue;
            }
            if (matchedKey == null) {
                matchedKey = key;
            } else if (!matchedKey.equals(key)) {
                // 有多个选项都等于正确答案（重复选项），只认一个 key 对孩子不公平 → 放弃选项
                return null;
            }
        }

        if (matchedKey == null) {
            // 正确答案不在选项里 → 这道选择题无解
            return null;
        }
        return new String[]{replacedOptions, matchedKey};
    }

    /**
     * 判断计算出的答案是否就是某个选项（选项文本可能带单位，如 "15支"）。
     * 纯数字选项按数值比较；带单位时要求选项文本以该数字开头且后面不再有数字（避免 1 命中 10）。
     */
    private boolean answerMatchesOption(String answer, String optionText) {
        if (answer == null || optionText == null) {
            return false;
        }
        String a = answer.trim();
        String t = optionText.trim();
        if (a.isEmpty() || t.isEmpty()) {
            return false;
        }
        if (isDigits(t)) {
            return isDigits(a) && sameNumber(a, t);
        }
        if (!isDigits(a)) {
            return a.equalsIgnoreCase(t);
        }
        // 选项带单位：取出前导数字，要求与答案相同，且剩余部分不含数字
        int i = 0;
        while (i < t.length() && Character.isDigit(t.charAt(i))) {
            i++;
        }
        String leading = t.substring(0, i);
        String rest = t.substring(i);
        return !leading.isEmpty()
                && sameNumber(leading, a)
                && extractNumbers(rest).isEmpty();
    }

    /** 纯数字字符串按数值比较（去掉前导 0 后逐位比较，避免 Integer.parseInt 溢出/抛异常） */
    private boolean sameNumber(String x, String y) {
        String a = stripLeadingZeros(x);
        String b = stripLeadingZeros(y);
        return a.length() == b.length() && a.equals(b);
    }

    private String stripLeadingZeros(String s) {
        int i = 0;
        while (i < s.length() - 1 && s.charAt(i) == '0') {
            i++;
        }
        return s.substring(i);
    }

    private boolean isDigits(String s) {
        if (s == null || s.isEmpty()) {
            return false;
        }
        for (int i = 0; i < s.length(); i++) {
            if (!Character.isDigit(s.charAt(i))) {
                return false;
            }
        }
        return true;
    }
}