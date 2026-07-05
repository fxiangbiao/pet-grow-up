package com.petgrowup.study.service;

import com.petgrowup.achievement.service.AchievementService;
import com.petgrowup.challenge.service.ChallengeService;
import com.petgrowup.story.service.StoryService;
import com.petgrowup.event.service.RandomEventService;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.common.exception.ResourceNotFoundException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.spirit.service.SpiritService;
import com.petgrowup.study.dto.AnswerResultDTO;
import com.petgrowup.study.dto.QuestionDTO;
import com.petgrowup.study.dto.StartSessionRequest;
import com.petgrowup.study.dto.SubmitAnswerRequest;
import com.petgrowup.study.entity.*;
import com.petgrowup.study.mapper.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ExplorationServiceTest {

    @Mock
    private StudySessionMapper sessionMapper;
    @Mock
    private StudyRecordMapper recordMapper;
    @Mock
    private QuizService quizService;
    @Mock
    private EnergyService energyService;
    @Mock
    private SpiritService spiritService;
    @Mock
    private UserMapper userMapper;
    @Mock
    private SubjectWorldMapper worldMapper;
    @Mock
    private SimpMessagingTemplate messagingTemplate;
    @Mock
    private AchievementService achievementService;
    @Mock
    private ChallengeService challengeService;
    @Mock
    private StoryService storyService;
    @Mock
    private RandomEventService randomEventService;

    private ExplorationService explorationService;

    @BeforeEach
    void setUp() {
        explorationService = new ExplorationService(sessionMapper, recordMapper, quizService,
                energyService, spiritService, userMapper, worldMapper, messagingTemplate, achievementService,
                challengeService, storyService, randomEventService);
    }

    @Test
    void startSession_shouldCreateSessionAndReturnFirstQuestion() {
        when(userMapper.selectOneById(1L)).thenReturn(User.builder().id(1L).build());
        when(quizService.getKnowledgeNodeById(1L)).thenReturn(KnowledgeNode.builder().id(1L).build());
        when(quizService.getQuestionsForSession(1L, 5)).thenReturn(List.of(
                QuestionDTO.builder().questionId(1L).questionText("Q1").build(),
                QuestionDTO.builder().questionId(2L).questionText("Q2").build()
        ));
        when(sessionMapper.insert(any())).thenReturn(1);

        QuestionDTO result = explorationService.startSession(1L,
                new StartSessionRequest("chinese", "DAILY", 1, 1L));

        assertNotNull(result);
        assertEquals("Q1", result.getQuestionText());
        verify(sessionMapper).insert(any());
    }

    @Test
    void startSession_shouldThrowWhenNoQuestions() {
        when(userMapper.selectOneById(1L)).thenReturn(User.builder().id(1L).build());
        when(quizService.getKnowledgeNodeById(1L)).thenReturn(KnowledgeNode.builder().id(1L).build());
        when(quizService.getQuestionsForSession(1L, 5)).thenReturn(List.of());

        assertThrows(BusinessException.class, () ->
                explorationService.startSession(1L, new StartSessionRequest("chinese", "DAILY", 1, 1L)));
    }

    @Test
    void submitAnswer_shouldRecordAndReturnResult() {
        long sessionId = 1L;
        StudySession session = StudySession.builder()
                .id(sessionId).userId(1L).status("IN_PROGRESS")
                .correctAnswers(0).totalQuestions(5).actualDuration(0)
                .build();

        when(sessionMapper.selectOneById(sessionId)).thenReturn(session);
        when(quizService.getQuestionById(1L)).thenReturn(
                QuizQuestion.builder().id(1L).knowledgeNodeId(1L).correctAnswer("A")
                        .questionType("MULTIPLE_CHOICE").explanation("Test").points(10).build());
        when(recordMapper.selectCountByQuery(any())).thenReturn(1L);

        AnswerResultDTO result = explorationService.submitAnswer(1L,
                new SubmitAnswerRequest(sessionId, 1L, "A", 30));

        assertTrue(result.getIsCorrect());
        assertFalse(result.getIsSessionComplete());
        verify(recordMapper).insert(any());
    }

    @Test
    void submitAnswer_wrongAnswer_shouldMarkIncorrect() {
        long sessionId = 1L;
        StudySession session = StudySession.builder()
                .id(sessionId).userId(1L).status("IN_PROGRESS")
                .correctAnswers(0).totalQuestions(5).actualDuration(0)
                .build();

        when(sessionMapper.selectOneById(sessionId)).thenReturn(session);
        when(quizService.getQuestionById(1L)).thenReturn(
                QuizQuestion.builder().id(1L).knowledgeNodeId(1L).correctAnswer("B")
                        .questionType("MULTIPLE_CHOICE").explanation("Test").points(10).build());
        when(recordMapper.selectCountByQuery(any())).thenReturn(1L);

        AnswerResultDTO result = explorationService.submitAnswer(1L,
                new SubmitAnswerRequest(sessionId, 1L, "A", 30));

        assertFalse(result.getIsCorrect());
        assertEquals("B", result.getCorrectAnswer());
    }

    @Test
    void submitAnswer_completedSession_shouldFinalize() {
        long sessionId = 1L;
        StudySession session = StudySession.builder()
                .id(sessionId).userId(1L).status("IN_PROGRESS")
                .subject("chinese").correctAnswers(4).totalQuestions(5)
                .actualDuration(120).expectedDuration(120)
                .difficultyLevel(1).streakAtTime(1).baseReward(100L)
                .build();

        when(sessionMapper.selectOneById(sessionId)).thenReturn(session);
        when(quizService.getQuestionById(1L)).thenReturn(
                QuizQuestion.builder().id(1L).knowledgeNodeId(1L).correctAnswer("A")
                        .questionType("MULTIPLE_CHOICE").explanation("Test").points(10).build());
        when(recordMapper.selectCountByQuery(any())).thenReturn(5L);
        when(userMapper.selectOneById(1L)).thenReturn(User.builder().id(1L).build());
        when(worldMapper.selectOneByQuery(any())).thenReturn(null);

        AnswerResultDTO result = explorationService.submitAnswer(1L,
                new SubmitAnswerRequest(sessionId, 1L, "A", 30));

        assertTrue(result.getIsSessionComplete());
        verify(sessionMapper).update(argThat(s -> "COMPLETED".equals(s.getStatus())));
    }

    @Test
    void submitAnswer_otherUserSession_shouldThrow() {
        StudySession session = StudySession.builder().id(1L).userId(2L).status("IN_PROGRESS").build();
        when(sessionMapper.selectOneById(1L)).thenReturn(session);

        assertThrows(BusinessException.class, () ->
                explorationService.submitAnswer(1L, new SubmitAnswerRequest(1L, 1L, "A", 30)));
    }

    @Test
    void submitAnswer_alreadyCompleted_shouldThrow() {
        StudySession session = StudySession.builder().id(1L).userId(1L).status("COMPLETED").build();
        when(sessionMapper.selectOneById(1L)).thenReturn(session);

        assertThrows(BusinessException.class, () ->
                explorationService.submitAnswer(1L, new SubmitAnswerRequest(1L, 1L, "A", 30)));
    }

    @Test
    void getSessionResult_shouldReturnResult() {
        long sessionId = 1L;
        long userId = 1L;
        StudySession session = StudySession.builder()
                .id(sessionId).totalQuestions(5).correctAnswers(4)
                .accuracy(BigDecimal.valueOf(0.8)).energyEarned(150L)
                .streakAtTime(3).build();
        when(sessionMapper.selectOneById(sessionId)).thenReturn(session);
        when(userMapper.selectOneById(userId)).thenReturn(User.builder().id(userId).currentSpiritId(1L).build());
        when(spiritService.getSpiritReaction(1L, 0.8)).thenReturn("HAPPY");

        var result = explorationService.getSessionResult(sessionId, userId, 0, false);
        assertEquals(sessionId, result.getSessionId());
        assertEquals(5, result.getTotalQuestions());
        assertEquals(4, result.getCorrectAnswers());
        assertTrue(result.getStreakMaintained());
    }

    @Test
    void completeSession_shouldUpdatePersonality() {
        long sessionId = 1L;
        long userId = 1L;
        StudySession session = StudySession.builder()
                .id(sessionId).userId(userId).status("IN_PROGRESS")
                .subject("chinese").correctAnswers(4).totalQuestions(5)
                .actualDuration(120).expectedDuration(120)
                .difficultyLevel(1).streakAtTime(3).baseReward(100L)
                .build();

        when(sessionMapper.selectOneById(sessionId)).thenReturn(session);
        when(quizService.getQuestionById(1L)).thenReturn(
                QuizQuestion.builder().id(1L).knowledgeNodeId(1L).correctAnswer("A")
                        .questionType("MULTIPLE_CHOICE").explanation("Test").points(10).build());
        when(recordMapper.selectCountByQuery(any())).thenReturn(5L);
        when(userMapper.selectOneById(userId)).thenReturn(User.builder().id(userId).currentSpiritId(1L).build());
        when(worldMapper.selectOneByQuery(any())).thenReturn(null);
        when(spiritService.getSpiritReaction(anyLong(), anyDouble())).thenReturn("HAPPY");

        explorationService.submitAnswer(userId, new SubmitAnswerRequest(sessionId, 1L, "A", 30));

        verify(spiritService).updatePersonalityAfterStudy(1L, 1.0, 150, 120, 3);
    }
}
