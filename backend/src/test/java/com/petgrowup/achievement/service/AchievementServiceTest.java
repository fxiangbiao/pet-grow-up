package com.petgrowup.achievement.service;

import com.petgrowup.achievement.checker.AchievementChecker;
import com.petgrowup.achievement.dto.AchievementProgressDTO;
import com.petgrowup.achievement.dto.AchievementUnlockEvent;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.entity.UserAchievement;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.achievement.mapper.AchievementDefMapper;
import com.petgrowup.achievement.mapper.UserAchievementMapper;
import com.petgrowup.energy.service.EnergyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AchievementServiceTest {

    @Mock
    private AchievementDefMapper defMapper;
    @Mock
    private UserAchievementMapper userAchievementMapper;
    @Mock
    private AchievementCheckerRegistry checkerRegistry;
    @Mock
    private EnergyService energyService;
    @Mock
    private SimpMessagingTemplate messagingTemplate;
    @Mock
    private AchievementChecker checker;

    private AchievementService achievementService;

    private AchievementDef sessionCountDef;
    private AchievementDef streakDef;

    @BeforeEach
    void setUp() {
        achievementService = new AchievementService(defMapper, userAchievementMapper,
                checkerRegistry, energyService, messagingTemplate);

        sessionCountDef = AchievementDef.builder()
                .id(1L).achievementKey("first_study").category("STUDY")
                .name("初次探索").description("完成首次学习")
                .rarity("COMMON").requirementType("SESSION_COUNT")
                .requirementThreshold(1L).rewardEnergy(50L)
                .displayOrder(1).isHidden(false).build();

        streakDef = AchievementDef.builder()
                .id(2L).achievementKey("streak_3_days").category("STUDY")
                .name("坚持三天").description("连续学习3天")
                .rarity("COMMON").requirementType("STREAK_DAYS")
                .requirementThreshold(3L).rewardEnergy(100L)
                .displayOrder(2).isHidden(false).build();
    }

    @Test
    void initializeUserAchievements_shouldCreateRecordsForAllDefs() {
        when(defMapper.selectAll()).thenReturn(List.of(sessionCountDef, streakDef));
        when(userAchievementMapper.selectOneByQuery(any())).thenReturn(null);
        when(checkerRegistry.getChecker(any())).thenReturn(checker);
        when(checker.getCurrentValue(any(), any())).thenReturn(0L);

        achievementService.initializeUserAchievements(1L);

        verify(userAchievementMapper, times(2)).insert(any());
        verify(userAchievementMapper).insert(argThat(ua ->
                ua.getUserId().equals(1L) && ua.getAchievementDefId().equals(1L)
                        && !ua.getIsUnlocked()));
        verify(userAchievementMapper).insert(argThat(ua ->
                ua.getUserId().equals(1L) && ua.getAchievementDefId().equals(2L)));
    }

    @Test
    void initializeUserAchievements_shouldNotDuplicateExisting() {
        when(defMapper.selectAll()).thenReturn(List.of(sessionCountDef));
        UserAchievement existing = UserAchievement.builder()
                .id(1L).userId(1L).achievementDefId(1L)
                .currentValue(1L).isUnlocked(true).build();
        when(userAchievementMapper.selectOneByQuery(any())).thenReturn(existing);

        achievementService.initializeUserAchievements(1L);

        verify(userAchievementMapper, never()).insert(any());
    }

    @Test
    void checkAndUnlock_shouldUnlockWhenThresholdMet() {
        when(defMapper.selectListByQuery(any())).thenReturn(List.of(sessionCountDef));
        when(checkerRegistry.getChecker(RequirementType.SESSION_COUNT)).thenReturn(checker);
        when(userAchievementMapper.selectOneByQuery(any())).thenReturn(null);

        doAnswer(invocation -> {
            UserAchievement ua = invocation.getArgument(2);
            AchievementDef def = invocation.getArgument(1);
            ua.setCurrentValue(def.getRequirementThreshold());
            return true;
        }).when(checker).check(any(), any(), any(), any());

        List<AchievementUnlockEvent> events = achievementService.checkAndUnlock(
                1L, RequirementType.SESSION_COUNT, Map.of());

        assertEquals(1, events.size());
        assertEquals("first_study", events.get(0).getAchievement().getAchievementKey());
        assertEquals(50L, events.get(0).getEnergyRewarded());
        verify(userAchievementMapper).insert(any());
        verify(userAchievementMapper).update(argThat(ua ->
                Boolean.TRUE.equals(ua.getIsUnlocked())));
        verify(energyService).earnEnergy(eq(1L), eq(50L), any(), any(), any());
        verify(messagingTemplate).convertAndSendToUser(
                eq("1"), eq("/topic/achievements"), any());
    }

    @Test
    void checkAndUnlock_shouldNotDuplicateUnlock() {
        when(defMapper.selectListByQuery(any())).thenReturn(List.of(sessionCountDef));
        when(checkerRegistry.getChecker(RequirementType.SESSION_COUNT)).thenReturn(checker);
        UserAchievement alreadyUnlocked = UserAchievement.builder()
                .id(1L).userId(1L).achievementDefId(1L)
                .currentValue(1L).isUnlocked(true).unlockedAt(LocalDateTime.now())
                .build();
        when(userAchievementMapper.selectOneByQuery(any())).thenReturn(alreadyUnlocked);

        List<AchievementUnlockEvent> events = achievementService.checkAndUnlock(
                1L, RequirementType.SESSION_COUNT, Map.of());

        assertTrue(events.isEmpty());
        verify(checker, never()).check(any(), any(), any(), any());
        verify(energyService, never()).earnEnergy(any(), anyLong(), any(), any(), any());
    }

    @Test
    void checkAndUnlock_subjectMilestone_shouldUnlock() {
        AchievementDef milestoneDef = AchievementDef.builder()
                .id(3L).achievementKey("chinese_10_poems").category("SUBJECT")
                .name("诗词入门").description("完成10次语文学习")
                .rarity("RARE").requirementType("SUBJECT_MILESTONE")
                .requirementThreshold(10L).subject("chinese").rewardEnergy(100L)
                .displayOrder(3).isHidden(false).build();

        when(defMapper.selectListByQuery(any())).thenReturn(List.of(milestoneDef));
        when(checkerRegistry.getChecker(RequirementType.SUBJECT_MILESTONE)).thenReturn(checker);
        when(userAchievementMapper.selectOneByQuery(any())).thenReturn(null);

        doAnswer(invocation -> {
            UserAchievement ua = invocation.getArgument(2);
            AchievementDef def = invocation.getArgument(1);
            ua.setCurrentValue(def.getRequirementThreshold());
            return true;
        }).when(checker).check(any(), any(), any(), any());

        List<AchievementUnlockEvent> events = achievementService.checkAndUnlock(
                1L, RequirementType.SUBJECT_MILESTONE,
                Map.of("subject", "chinese"));

        assertEquals(1, events.size());
        assertEquals("chinese_10_poems", events.get(0).getAchievement().getAchievementKey());
        verify(energyService).earnEnergy(eq(1L), eq(100L), any(), any(), any());
    }

    @Test
    void getUserAchievements_shouldGroupUnlockedAndInProgress() {
        AchievementDef hiddenDef = AchievementDef.builder()
                .id(4L).achievementKey("hidden_one").category("EVENT")
                .name("隐藏成就").description("隐藏的")
                .rarity("LEGENDARY").requirementType("SESSION_COUNT")
                .requirementThreshold(999L).rewardEnergy(0L)
                .displayOrder(4).isHidden(true).build();
        AchievementDef noProgressDef = AchievementDef.builder()
                .id(5L).achievementKey("perfect_session").category("STUDY")
                .name("完美答卷").description("完美完成一次学习")
                .rarity("RARE").requirementType("PERFECT_SESSION")
                .requirementThreshold(1L).rewardEnergy(200L)
                .displayOrder(5).isHidden(false).build();

        when(defMapper.selectAll()).thenReturn(List.of(
                sessionCountDef, streakDef, hiddenDef, noProgressDef));

        UserAchievement unlocked = UserAchievement.builder()
                .id(1L).userId(1L).achievementDefId(1L)
                .currentValue(1L).isUnlocked(true).notified(false).build();
        UserAchievement inProgress = UserAchievement.builder()
                .id(2L).userId(1L).achievementDefId(2L)
                .currentValue(1L).isUnlocked(false).notified(false).build();

        when(userAchievementMapper.selectListByQuery(any())).thenReturn(
                List.of(unlocked, inProgress));

        AchievementProgressDTO result = achievementService.getUserAchievements(1L);

        assertEquals(1, result.getUnlockedCount());
        assertEquals(4, result.getTotalCount());
        assertEquals(1, result.getUnlocked().size());
        assertEquals(2, result.getInProgress().size());
        assertEquals("first_study", result.getUnlocked().get(0).getDefinition().getAchievementKey());
    }
}
