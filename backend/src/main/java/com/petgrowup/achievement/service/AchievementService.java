package com.petgrowup.achievement.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.checker.AchievementChecker;
import com.petgrowup.achievement.dto.*;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.entity.UserAchievement;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.achievement.mapper.AchievementDefMapper;
import com.petgrowup.achievement.mapper.UserAchievementMapper;
import com.petgrowup.energy.service.EnergyService;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AchievementService {

    private final AchievementDefMapper defMapper;
    private final UserAchievementMapper userAchievementMapper;
    private final AchievementCheckerRegistry checkerRegistry;
    private final EnergyService energyService;
    private final SimpMessagingTemplate messagingTemplate;

    public AchievementService(AchievementDefMapper defMapper,
                              UserAchievementMapper userAchievementMapper,
                              AchievementCheckerRegistry checkerRegistry,
                              EnergyService energyService,
                              SimpMessagingTemplate messagingTemplate) {
        this.defMapper = defMapper;
        this.userAchievementMapper = userAchievementMapper;
        this.checkerRegistry = checkerRegistry;
        this.energyService = energyService;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public void initializeUserAchievements(Long userId) {
        List<AchievementDef> allDefs = defMapper.selectAll();
        for (AchievementDef def : allDefs) {
            UserAchievement existing = userAchievementMapper.selectOneByQuery(
                    QueryWrapper.create()
                            .eq("user_id", userId)
                            .eq("achievement_def_id", def.getId()));
            if (existing != null) continue;

            RequirementType type = RequirementType.valueOf(def.getRequirementType());
            AchievementChecker checker = checkerRegistry.getChecker(type);
            long currentValue = checker.getCurrentValue(userId, def);

            UserAchievement ua = UserAchievement.builder()
                    .userId(userId)
                    .achievementDefId(def.getId())
                    .currentValue(currentValue)
                    .isUnlocked(currentValue >= def.getRequirementThreshold())
                    .unlockedAt(currentValue >= def.getRequirementThreshold() ? LocalDateTime.now() : null)
                    .notified(false)
                    .build();
            userAchievementMapper.insert(ua);
        }
    }

    @Transactional
    public List<AchievementUnlockEvent> checkAndUnlock(Long userId, RequirementType type, Map<String, Object> context) {
        List<AchievementDef> defs = defMapper.selectListByQuery(
                QueryWrapper.create().eq("requirement_type", type.name()));

        AchievementChecker checker = checkerRegistry.getChecker(type);
        List<AchievementUnlockEvent> newUnlocks = new ArrayList<>();

        for (AchievementDef def : defs) {
            UserAchievement ua = userAchievementMapper.selectOneByQuery(
                    QueryWrapper.create()
                            .eq("user_id", userId)
                            .eq("achievement_def_id", def.getId()));

            if (ua == null) {
                ua = UserAchievement.builder()
                        .userId(userId)
                        .achievementDefId(def.getId())
                        .currentValue(0L)
                        .isUnlocked(false)
                        .notified(false)
                        .build();
                userAchievementMapper.insert(ua);
            }

            if (Boolean.TRUE.equals(ua.getIsUnlocked())) continue;

            boolean meetsThreshold = checker.check(userId, def, ua, context);

            if (meetsThreshold && ua.getCurrentValue() >= def.getRequirementThreshold()) {
                ua.setIsUnlocked(true);
                ua.setUnlockedAt(LocalDateTime.now());
                userAchievementMapper.update(ua);

                if (def.getRewardEnergy() > 0) {
                    energyService.earnEnergy(userId, def.getRewardEnergy(), "achievement",
                            "achievement_def", def.getId());
                }

                AchievementDefDTO dto = toDefDTO(def);
                AchievementUnlockEvent event = AchievementUnlockEvent.builder()
                        .userId(userId)
                        .achievement(dto)
                        .energyRewarded(def.getRewardEnergy())
                        .titleGranted(def.getRewardTitle())
                        .build();
                newUnlocks.add(event);

                messagingTemplate.convertAndSendToUser(
                        userId.toString(), "/topic/achievements", event);
            } else {
                userAchievementMapper.update(ua);
            }
        }
        return newUnlocks;
    }

    public AchievementProgressDTO getUserAchievements(Long userId) {
        List<AchievementDef> allDefs = defMapper.selectAll();
        List<UserAchievement> userAchievements = userAchievementMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));

        Map<Long, AchievementDef> defMap = allDefs.stream()
                .collect(Collectors.toMap(AchievementDef::getId, d -> d));

        List<UserAchievementDTO> unlocked = new ArrayList<>();
        List<UserAchievementDTO> inProgress = new ArrayList<>();

        for (AchievementDef def : allDefs) {
            if (Boolean.TRUE.equals(def.getIsHidden())) continue;

            UserAchievement ua = userAchievements.stream()
                    .filter(a -> a.getAchievementDefId().equals(def.getId()))
                    .findFirst().orElse(null);

            if (ua == null) {
                inProgress.add(toUserAchievementDTO(null, def, 0L, false));
                continue;
            }

            UserAchievementDTO dto = toUserAchievementDTO(ua, def,
                    ua.getCurrentValue(), Boolean.TRUE.equals(ua.getIsUnlocked()));

            if (Boolean.TRUE.equals(ua.getIsUnlocked())) {
                unlocked.add(dto);
            } else {
                inProgress.add(dto);
            }
        }

        unlocked.sort(Comparator.comparingInt(a -> a.getDefinition().getDisplayOrder()));
        inProgress.sort(Comparator.comparingInt(a -> a.getDefinition().getDisplayOrder()));

        return AchievementProgressDTO.builder()
                .unlocked(unlocked)
                .inProgress(inProgress)
                .totalCount(allDefs.size())
                .unlockedCount(unlocked.size())
                .build();
    }

    @Transactional
    public void markNotified(Long userId, Long userAchievementId) {
        UserAchievement ua = userAchievementMapper.selectOneById(userAchievementId);
        if (ua != null && ua.getUserId().equals(userId)) {
            ua.setNotified(true);
            userAchievementMapper.update(ua);
        }
    }

    private AchievementDefDTO toDefDTO(AchievementDef def) {
        return AchievementDefDTO.builder()
                .id(def.getId())
                .achievementKey(def.getAchievementKey())
                .category(def.getCategory())
                .name(def.getName())
                .description(def.getDescription())
                .iconUrl(def.getIconUrl())
                .rarity(def.getRarity())
                .requirementType(def.getRequirementType())
                .requirementThreshold(def.getRequirementThreshold())
                .subject(def.getSubject())
                .rewardEnergy(def.getRewardEnergy())
                .rewardItemKey(def.getRewardItemKey())
                .rewardTitle(def.getRewardTitle())
                .displayOrder(def.getDisplayOrder())
                .isHidden(def.getIsHidden())
                .build();
    }

    private UserAchievementDTO toUserAchievementDTO(UserAchievement ua, AchievementDef def,
                                                     Long currentValue, boolean unlocked) {
        return UserAchievementDTO.builder()
                .id(ua != null ? ua.getId() : null)
                .achievementDefId(def.getId())
                .definition(toDefDTO(def))
                .currentValue(currentValue)
                .isUnlocked(unlocked)
                .unlockedAt(ua != null ? ua.getUnlockedAt() : null)
                .notified(ua != null ? ua.getNotified() : false)
                .build();
    }
}
