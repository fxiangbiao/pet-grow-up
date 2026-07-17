package com.petgrowup.study.service;

import com.petgrowup.study.dto.QuestionDTO;
import com.petgrowup.study.entity.QuizQuestion;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import com.mybatisflex.core.query.QueryWrapper;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static com.petgrowup.study.entity.table.QuizQuestionTableDef.QUIZ_QUESTION;

@Service
public class QuestionGeneratorService {

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

                result.put("questionText", newQuestionText);
                result.put("correctAnswer", newAnswer);
                result.put("questionType", questionType);
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
            QuizQuestion alt = alternatives.get(new Random().nextInt(alternatives.size()));
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
}