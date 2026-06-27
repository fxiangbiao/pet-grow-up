package com.petgrowup.study.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.achievement.service.AchievementService;
import com.petgrowup.challenge.service.ChallengeService;
import com.petgrowup.story.service.StoryService;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.common.exception.ResourceNotFoundException;
import com.petgrowup.common.util.EnergyCalculator;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.spirit.service.SpiritService;
import com.petgrowup.study.dto.*;
import com.petgrowup.study.entity.*;
import com.petgrowup.study.mapper.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ExplorationService {

    private final StudySessionMapper sessionMapper;
    private final StudyRecordMapper recordMapper;
    private final QuizService quizService;
    private final EnergyService energyService;
    private final SpiritService spiritService;
    private final UserMapper userMapper;
    private final SubjectWorldMapper worldMapper;
    private final SimpMessagingTemplate messagingTemplate;
    private final AchievementService achievementService;
    private final ChallengeService challengeService;
    private final StoryService storyService;

    private static final int QUESTIONS_PER_SESSION = 5;
    private static final long BASE_REWARD = 100;
    private static final int EXPECTED_DURATION_SECONDS = 120;

    public ExplorationService(StudySessionMapper sessionMapper, StudyRecordMapper recordMapper,
                              QuizService quizService, EnergyService energyService,
                              SpiritService spiritService, UserMapper userMapper,
                              SubjectWorldMapper worldMapper,
                              SimpMessagingTemplate messagingTemplate,
                              AchievementService achievementService,
                              ChallengeService challengeService,
                              StoryService storyService) {
        this.sessionMapper = sessionMapper;
        this.recordMapper = recordMapper;
        this.quizService = quizService;
        this.energyService = energyService;
        this.spiritService = spiritService;
        this.userMapper = userMapper;
        this.worldMapper = worldMapper;
        this.messagingTemplate = messagingTemplate;
        this.achievementService = achievementService;
        this.challengeService = challengeService;
        this.storyService = storyService;
    }

    @Transactional
    public QuestionDTO startSession(Long userId, StartSessionRequest request) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new ResourceNotFoundException("User", userId);

        KnowledgeNode node = quizService.getKnowledgeNodeById(request.getKnowledgeNodeId());
        if (node == null) throw new ResourceNotFoundException("KnowledgeNode", request.getKnowledgeNodeId());

        List<QuestionDTO> questions = quizService.getQuestionsForSession(request.getKnowledgeNodeId(), QUESTIONS_PER_SESSION);
        if (questions.isEmpty()) {
            throw new BusinessException("该节点暂无可用题目");
        }

        // Store pre-shuffled question order to prevent repeats
        String questionOrder = questions.stream()
                .map(q -> String.valueOf(q.getQuestionId()))
                .collect(Collectors.joining(","));

        int streak = updateStreak(user);

        StudySession session = StudySession.builder()
                .userId(userId)
                .subject(request.getSubject())
                .sessionType(request.getSessionType())
                .status("IN_PROGRESS")
                .difficultyLevel(request.getDifficultyLevel())
                .baseReward(BASE_REWARD)
                .totalQuestions(questions.size())
                .correctAnswers(0)
                .accuracy(BigDecimal.ZERO)
                .actualDuration(0)
                .expectedDuration(EXPECTED_DURATION_SECONDS)
                .energyEarned(0L)
                .streakAtTime(streak)
                .currentCombo(0)
                .maxCombo(0)
                .bossDefeated(false)
                .questionOrder(questionOrder)
                .startedAt(LocalDateTime.now())
                .build();

        sessionMapper.insert(session);

        QuestionDTO first = questions.get(0);
        first.setSessionId(session.getId());
        first.setTotalQuestions(questions.size());
        first.setAnsweredCount(0);
        return first;
    }

    @Transactional
    public AnswerResultDTO submitAnswer(Long userId, SubmitAnswerRequest request) {
        StudySession session = sessionMapper.selectOneById(request.getSessionId());
        if (session == null) throw new ResourceNotFoundException("Session", request.getSessionId());
        if (!session.getUserId().equals(userId)) throw new BusinessException("这不是你的学习会话");
        if ("COMPLETED".equals(session.getStatus())) throw new BusinessException("学习会话已完成");

        QuizQuestion question = quizService.getQuestionById(request.getQuestionId());
        if (question == null) throw new ResourceNotFoundException("Question", request.getQuestionId());

        boolean isCorrect = question.getCorrectAnswer().trim().equalsIgnoreCase(
                request.getAnswer() != null ? request.getAnswer().trim() : "");

        StudyRecord record = StudyRecord.builder()
                .sessionId(session.getId())
                .knowledgeNodeId(question.getKnowledgeNodeId())
                .questionId(question.getId())
                .questionType(question.getQuestionType())
                .userAnswer(request.getAnswer())
                .correctAnswer(question.getCorrectAnswer())
                .isCorrect(isCorrect)
                .timeSpent(request.getTimeSpent())
                .build();

        recordMapper.insert(record);

        // Update session
        int newCorrect = session.getCorrectAnswers() + (isCorrect ? 1 : 0);
        session.setCorrectAnswers(newCorrect);
        if (request.getTimeSpent() != null) {
            session.setActualDuration(session.getActualDuration() + request.getTimeSpent());
        }

        // Track combo and boss defeat
        int currentCombo = session.getCurrentCombo() != null ? session.getCurrentCombo() : 0;
        if (isCorrect) {
            currentCombo++;
            int maxCombo = session.getMaxCombo() != null ? session.getMaxCombo() : 0;
            if (currentCombo > maxCombo) {
                session.setMaxCombo(currentCombo);
            }
        } else {
            currentCombo = 0;
        }
        session.setCurrentCombo(currentCombo);

        // Check if session is complete
        long answeredCount = recordMapper.selectCountByQuery(
                QueryWrapper.create().eq("session_id", session.getId()));

        boolean isSessionComplete = answeredCount >= session.getTotalQuestions();

        // Last question correct = boss defeated
        if (isSessionComplete && isCorrect) {
            session.setBossDefeated(true);
        }

        if (isSessionComplete) {
            completeSession(session, userId);
        } else {
            sessionMapper.update(session);
        }

        // Push real-time progress via WebSocket
        messagingTemplate.convertAndSend(
                "/topic/session/" + session.getId() + "/progress",
                Map.of("answeredCount", answeredCount, "totalQuestions", session.getTotalQuestions(),
                       "isCorrect", isCorrect, "isComplete", isSessionComplete));

        QuestionDTO nextQuestion = null;
        if (!isSessionComplete) {
            List<Long> answeredIds = recordMapper.selectListByQuery(
                            QueryWrapper.create().eq("session_id", session.getId()))
                    .stream().map(StudyRecord::getQuestionId)
                    .collect(Collectors.toList());

            // Use pre-shuffled question order to ensure each question appears exactly once
            String order = session.getQuestionOrder();
            if (order != null && !order.isEmpty()) {
                for (String idStr : order.split(",")) {
                    Long qId = Long.parseLong(idStr.trim());
                    if (!answeredIds.contains(qId)) {
                        QuizQuestion q = quizService.getQuestionById(qId);
                        nextQuestion = QuestionDTO.builder()
                                .questionId(q.getId())
                                .questionType(q.getQuestionType())
                                .questionText(q.getQuestionText())
                                .options(q.getOptions())
                                .points(q.getPoints())
                                .build();
                        nextQuestion.setTotalQuestions(session.getTotalQuestions());
                        nextQuestion.setAnsweredCount((int) answeredCount);
                        break;
                    }
                }
            }
        }

        return AnswerResultDTO.builder()
                .isCorrect(isCorrect)
                .correctAnswer(question.getCorrectAnswer())
                .explanation(question.getExplanation())
                .pointsEarned(isCorrect ? question.getPoints() : 0)
                .isSessionComplete(isSessionComplete)
                .isLastQuestion(isSessionComplete)
                .nextQuestion(nextQuestion)
                .build();
    }

    public SessionResultDTO getSessionResult(Long sessionId, Long userId, int maxCombo, boolean bossDefeated) {
        StudySession session = sessionMapper.selectOneById(sessionId);
        if (session == null) throw new ResourceNotFoundException("Session", sessionId);

        long comboBonus = maxCombo > 1 ? (long) (maxCombo - 1) * 10 : 0;

        String spiritReaction = "CONTENT";
        if (userId != null) {
            User user = userMapper.selectOneById(userId);
            if (user != null && user.getCurrentSpiritId() != null) {
                spiritReaction = spiritService.getSpiritReaction(
                        user.getCurrentSpiritId(), session.getAccuracy().doubleValue());
            }
        }

        return SessionResultDTO.builder()
                .sessionId(session.getId())
                .totalQuestions(session.getTotalQuestions())
                .correctAnswers(session.getCorrectAnswers())
                .accuracy(session.getAccuracy().doubleValue())
                .energyEarned(session.getEnergyEarned())
                .streakMaintained(session.getStreakAtTime() > 0)
                .spiritReaction(spiritReaction)
                .maxCombo(maxCombo)
                .bossDefeated(bossDefeated)
                .comboBonusEnergy(comboBonus)
                .build();
    }

    private void completeSession(StudySession session, Long userId) {
        double accuracy = session.getTotalQuestions() > 0
                ? (double) session.getCorrectAnswers() / session.getTotalQuestions()
                : 0.0;

        session.setAccuracy(BigDecimal.valueOf(accuracy).setScale(2, RoundingMode.HALF_UP));

        User user = userMapper.selectOneById(userId);

        double difficultyCoeff = 1.0 + (session.getDifficultyLevel() - 1) * 0.5;
        double subjectCoeff = 1.2;

        long baseEnergy = EnergyCalculator.calculateFinalEnergy(
                session.getBaseReward(),
                accuracy,
                session.getActualDuration(),
                session.getExpectedDuration(),
                session.getStreakAtTime(),
                difficultyCoeff,
                subjectCoeff
        );

        // Add combo bonus to actual earned energy (not just display)
        long comboBonus = session.getMaxCombo() != null && session.getMaxCombo() > 1
                ? (long) (session.getMaxCombo() - 1) * 10 : 0;
        long energyEarned = baseEnergy + comboBonus;

        session.setEnergyEarned(energyEarned);
        session.setStatus("COMPLETED");
        session.setCompletedAt(LocalDateTime.now());
        sessionMapper.update(session);

        energyService.earnEnergy(userId, energyEarned, "study_session", "study_session", session.getId());

        // Update spirit affection and personality
        if (user.getCurrentSpiritId() != null) {
            int affectionGain = accuracy >= 0.8 ? 5 : accuracy >= 0.6 ? 3 : 1;
            spiritService.updateAffection(user.getCurrentSpiritId(), affectionGain);
            spiritService.updatePersonalityAfterStudy(
                    user.getCurrentSpiritId(), accuracy,
                    session.getActualDuration(), session.getExpectedDuration(),
                    session.getStreakAtTime());
        }

        // Update subject world progress
        updateWorldProgress(userId, session);

        // Push session result via WebSocket (with actual combo/boss values)
        int maxCombo = session.getMaxCombo() != null ? session.getMaxCombo() : 0;
        boolean bossDefeated = session.getBossDefeated() != null ? session.getBossDefeated() : false;
        messagingTemplate.convertAndSend(
                "/topic/session/" + session.getId() + "/complete",
                getSessionResult(session.getId(), userId, maxCombo, bossDefeated));

        // Check achievements
        Map<String, Object> ctx = Map.of(
                "subject", session.getSubject(),
                "accuracy", accuracy,
                "sessionId", session.getId(),
                "streak", session.getStreakAtTime()
        );
        achievementService.checkAndUnlock(userId, RequirementType.SESSION_COUNT, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.STREAK_DAYS, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.PERFECT_SESSION, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.ALL_SUBJECTS_TRIED, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.SUBJECT_MILESTONE, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.TOTAL_ENERGY, ctx);
        achievementService.checkAndUnlock(userId, RequirementType.MAX_AFFECTION, ctx);

        // Update daily challenge progress
        challengeService.updateProgress(userId, session);

        // Check story chapter conditions
        storyService.checkAllConditions(userId);
    }

    private void updateWorldProgress(Long userId, StudySession session) {
        double accuracy = session.getAccuracy() != null ? session.getAccuracy().doubleValue() : 0.0;
        int earnedStars;
        if (accuracy >= 0.8) earnedStars = 3;
        else if (accuracy >= 0.6) earnedStars = 2;
        else if (accuracy >= 0.4) earnedStars = 1;
        else earnedStars = 0;

        SubjectWorld world = worldMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("subject", session.getSubject()));

        if (world == null) {
            world = SubjectWorld.builder()
                    .userId(userId)
                    .subject(session.getSubject())
                    .worldLevel(1)
                    .totalStars(earnedStars)
                    .mapData("{}")
                    .build();
            worldMapper.insert(world);
        } else {
            world.setTotalStars(world.getTotalStars() + earnedStars);
            world.setWorldLevel((world.getTotalStars() / 10) + 1);
            worldMapper.update(world);
        }
    }

    private int updateStreak(User user) {
        LocalDate today = LocalDate.now();
        LocalDate lastStudy = user.getLastStudyDate();

        int streak;
        if (lastStudy == null) {
            streak = 1;
        } else if (lastStudy.equals(today)) {
            streak = user.getConsecutiveStudyDays();
        } else if (lastStudy.equals(today.minusDays(1))) {
            streak = user.getConsecutiveStudyDays() + 1;
        } else {
            streak = 1;
        }

        user.setConsecutiveStudyDays(streak);
        user.setLastStudyDate(today);
        userMapper.update(user);

        return streak;
    }
}
