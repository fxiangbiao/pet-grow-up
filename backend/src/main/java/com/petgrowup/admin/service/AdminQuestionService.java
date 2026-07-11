package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.QuestionPageDTO.QuestionRowDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.entity.QuizQuestion;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminQuestionService {

    private final QuizQuestionMapper questionMapper;
    private final KnowledgeNodeMapper nodeMapper;

    public AdminQuestionService(QuizQuestionMapper questionMapper, KnowledgeNodeMapper nodeMapper) {
        this.questionMapper = questionMapper;
        this.nodeMapper = nodeMapper;
    }

    public QuestionPageDTO listQuestions(QuestionFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        // Load all nodes once — reused for both filtering and display
        List<KnowledgeNode> allNodes = nodeMapper.selectListByQuery(QueryWrapper.create());
        Map<Long, KnowledgeNode> nodeMap = allNodes.stream()
                .collect(Collectors.toMap(KnowledgeNode::getId, n -> n));

        // Filter by subject/grade via node ids
        if (filter.getSubject() != null || filter.getGradeLevel() != null) {
            Set<Long> nodeIds = allNodes.stream()
                    .filter(n -> filter.getSubject() == null || filter.getSubject().equals(n.getSubject()))
                    .filter(n -> filter.getGradeLevel() == null || filter.getGradeLevel().equals(n.getGradeLevel()))
                    .map(KnowledgeNode::getId)
                    .collect(Collectors.toSet());
            if (nodeIds.isEmpty()) {
                return QuestionPageDTO.builder()
                        .items(Collections.emptyList()).total(0)
                        .page(filter.getPage()).size(filter.getSize()).build();
            }
            qw.in("knowledge_node_id", nodeIds);
        }

        if (filter.getKnowledgeNodeId() != null) {
            qw.eq("knowledge_node_id", filter.getKnowledgeNodeId());
        }
        if (filter.getQuestionType() != null && !filter.getQuestionType().isBlank()) {
            qw.eq("question_type", filter.getQuestionType());
        }
        if (filter.getDifficulty() != null) {
            qw.eq("difficulty", filter.getDifficulty());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("question_text", "%" + filter.getKeyword() + "%");
        }

        // Count total
        long total = questionMapper.selectCountByQuery(qw);

        // Paginate
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("id", false);

        List<QuizQuestion> questions = questionMapper.selectListByQuery(qw);


        List<QuestionRowDTO> rows = questions.stream().map(q -> {
            KnowledgeNode node = nodeMap.get(q.getKnowledgeNodeId());
            return QuestionRowDTO.builder()
                    .id(q.getId())
                    .questionType(q.getQuestionType())
                    .difficulty(q.getDifficulty())
                    .questionText(q.getQuestionText() != null && q.getQuestionText().length() > 60
                            ? q.getQuestionText().substring(0, 60) + "..." : q.getQuestionText())
                    .options(q.getOptions())
                    .correctAnswer(q.getCorrectAnswer())
                    .explanation(q.getExplanation())
                    .points(q.getPoints())
                    .knowledgeNodeId(q.getKnowledgeNodeId())
                    .knowledgeNodeName(node != null ? node.getName() : null)
                    .subject(node != null ? node.getSubject() : null)
                    .gradeLevel(node != null ? node.getGradeLevel() : null)
                    .createdAt(q.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());

        return QuestionPageDTO.builder()
                .items(rows).total(total).page(page).size(size).build();
    }

    public QuizQuestion getQuestion(Long id) {
        QuizQuestion q = questionMapper.selectOneById(id);
        if (q == null) throw new BusinessException(404, "题目不存在");
        return q;
    }

    @Transactional
    public QuizQuestion createQuestion(CreateQuestionDTO dto) {
        // Validate node exists
        if (nodeMapper.selectOneById(dto.getKnowledgeNodeId()) == null) {
            throw new BusinessException("知识节点不存在");
        }

        QuizQuestion q = QuizQuestion.builder()
                .knowledgeNodeId(dto.getKnowledgeNodeId())
                .questionType(dto.getQuestionType())
                .difficulty(dto.getDifficulty() != null ? dto.getDifficulty() : 1)
                .questionText(dto.getQuestionText())
                .options(dto.getOptions())
                .correctAnswer(dto.getCorrectAnswer())
                .explanation(dto.getExplanation())
                .points(dto.getPoints() != null ? dto.getPoints() : 10)
                .build();
        questionMapper.insert(q);
        return q;
    }

    @Transactional
    public QuizQuestion updateQuestion(Long id, UpdateQuestionDTO dto) {
        QuizQuestion q = questionMapper.selectOneById(id);
        if (q == null) throw new BusinessException(404, "题目不存在");

        if (dto.getKnowledgeNodeId() != null) {
            if (nodeMapper.selectOneById(dto.getKnowledgeNodeId()) == null) {
                throw new BusinessException("知识节点不存在");
            }
            q.setKnowledgeNodeId(dto.getKnowledgeNodeId());
        }
        if (dto.getQuestionType() != null) q.setQuestionType(dto.getQuestionType());
        if (dto.getDifficulty() != null) q.setDifficulty(dto.getDifficulty());
        if (dto.getQuestionText() != null) q.setQuestionText(dto.getQuestionText());
        if (dto.getOptions() != null) q.setOptions(dto.getOptions());
        if (dto.getCorrectAnswer() != null) q.setCorrectAnswer(dto.getCorrectAnswer());
        if (dto.getExplanation() != null) q.setExplanation(dto.getExplanation());
        if (dto.getPoints() != null) q.setPoints(dto.getPoints());

        questionMapper.update(q);
        return q;
    }

    @Transactional
    public void deleteQuestion(Long id) {
        if (questionMapper.selectOneById(id) == null) {
            throw new BusinessException(404, "题目不存在");
        }
        questionMapper.deleteById(id);
    }

    @Transactional
    public BatchImportResultDTO batchImport(List<CreateQuestionDTO> questions) {
        int success = 0;
        List<String> errors = new ArrayList<>();

        for (int i = 0; i < questions.size(); i++) {
            CreateQuestionDTO dto = questions.get(i);
            try {
                if (dto.getKnowledgeNodeId() == null) {
                    errors.add("Row " + (i + 1) + ": knowledgeNodeId is required");
                    continue;
                }
                if (dto.getQuestionType() == null || dto.getQuestionType().isBlank()) {
                    errors.add("Row " + (i + 1) + ": questionType is required");
                    continue;
                }
                if (dto.getQuestionText() == null || dto.getQuestionText().isBlank()) {
                    errors.add("Row " + (i + 1) + ": questionText is required");
                    continue;
                }
                if (dto.getCorrectAnswer() == null || dto.getCorrectAnswer().isBlank()) {
                    errors.add("Row " + (i + 1) + ": correctAnswer is required");
                    continue;
                }
                createQuestion(dto);
                success++;
            } catch (Exception e) {
                errors.add("Row " + (i + 1) + ": " + e.getMessage());
            }
        }

        return BatchImportResultDTO.builder()
                .successCount(success)
                .errorCount(errors.size())
                .errors(errors)
                .build();
    }
}
