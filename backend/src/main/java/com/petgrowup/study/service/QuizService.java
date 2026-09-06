package com.petgrowup.study.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.study.dto.QuestionDTO;
import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.entity.QuizQuestion;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import static com.petgrowup.study.entity.table.QuizQuestionTableDef.QUIZ_QUESTION;

@Service
public class QuizService {

    private final QuizQuestionMapper questionMapper;
    private final KnowledgeNodeMapper knowledgeNodeMapper;

    public QuizService(QuizQuestionMapper questionMapper, KnowledgeNodeMapper knowledgeNodeMapper) {
        this.questionMapper = questionMapper;
        this.knowledgeNodeMapper = knowledgeNodeMapper;
    }

    public List<QuestionDTO> getQuestionsForSession(Long knowledgeNodeId, int count) {
        List<QuizQuestion> questions = questionMapper.selectListByQuery(
                QueryWrapper.create()
                        .select(QUIZ_QUESTION.ID, QUIZ_QUESTION.QUESTION_TYPE,
                                QUIZ_QUESTION.QUESTION_TEXT, QUIZ_QUESTION.OPTIONS,
                                QUIZ_QUESTION.POINTS, QUIZ_QUESTION.KNOWLEDGE_NODE_ID)
                        .where(QUIZ_QUESTION.KNOWLEDGE_NODE_ID.eq(knowledgeNodeId))
        );
        Collections.shuffle(questions);

        return questions.stream()
                .limit(count)
                .map(q -> QuestionDTO.builder()
                        .questionId(q.getId())
                        .questionType(q.getQuestionType())
                        .questionText(q.getQuestionText())
                        .options(q.getOptions())
                        .points(q.getPoints())
                        .build()
                ).collect(Collectors.toList());
    }

    public QuizQuestion getQuestionById(Long questionId) {
        return questionMapper.selectOneByQuery(
                QueryWrapper.create()
                        .select(QUIZ_QUESTION.ID, QUIZ_QUESTION.KNOWLEDGE_NODE_ID,
                                QUIZ_QUESTION.QUESTION_TYPE, QUIZ_QUESTION.QUESTION_TEXT,
                                QUIZ_QUESTION.OPTIONS, QUIZ_QUESTION.CORRECT_ANSWER,
                                QUIZ_QUESTION.EXPLANATION, QUIZ_QUESTION.POINTS)
                        .where(QUIZ_QUESTION.ID.eq(questionId))
        );
    }


    /**
     * Get practice questions sorted by difficulty (low to high), limited to count.
     */
    public List<QuestionDTO> getPracticeQuestionsForSession(Long knowledgeNodeId, int count) {
        List<QuizQuestion> questions = questionMapper.selectListByQuery(
                QueryWrapper.create()
                        .select(QUIZ_QUESTION.ID, QUIZ_QUESTION.QUESTION_TYPE,
                                QUIZ_QUESTION.QUESTION_TEXT, QUIZ_QUESTION.OPTIONS,
                                QUIZ_QUESTION.POINTS, QUIZ_QUESTION.KNOWLEDGE_NODE_ID,
                                QUIZ_QUESTION.DIFFICULTY)
                        .where(QUIZ_QUESTION.KNOWLEDGE_NODE_ID.eq(knowledgeNodeId))
                        .orderBy(QUIZ_QUESTION.DIFFICULTY, true)
        );

        return questions.stream()
                .limit(count)
                .map(q -> QuestionDTO.builder()
                        .questionId(q.getId())
                        .questionType(q.getQuestionType())
                        .questionText(q.getQuestionText())
                        .options(q.getOptions())
                        .points(q.getPoints())
                        .build()
                ).collect(Collectors.toList());
    }

    public KnowledgeNode getKnowledgeNodeById(Long nodeId) {
        return knowledgeNodeMapper.selectOneById(nodeId);
    }
}
