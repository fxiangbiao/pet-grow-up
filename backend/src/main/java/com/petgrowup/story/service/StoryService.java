package com.petgrowup.story.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.UserAchievement;
import com.petgrowup.achievement.mapper.UserAchievementMapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.spirit.entity.LearningSpirit;
import com.petgrowup.spirit.mapper.SpiritMapper;
import com.petgrowup.story.dto.ChapterDTO;
import com.petgrowup.story.entity.StoryChapter;
import com.petgrowup.story.entity.UserStoryProgress;
import com.petgrowup.story.mapper.StoryChapterMapper;
import com.petgrowup.story.mapper.UserStoryProgressMapper;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class StoryService {

    private final StoryChapterMapper chapterMapper;
    private final UserStoryProgressMapper progressMapper;
    private final EnergyService energyService;
    private final UserMapper userMapper;
    private final SpiritMapper spiritMapper;
    private final StudySessionMapper sessionMapper;
    private final UserAchievementMapper achievementMapper;

    public StoryService(StoryChapterMapper chapterMapper, UserStoryProgressMapper progressMapper,
                        EnergyService energyService, UserMapper userMapper,
                        SpiritMapper spiritMapper, StudySessionMapper sessionMapper,
                        UserAchievementMapper achievementMapper) {
        this.chapterMapper = chapterMapper;
        this.progressMapper = progressMapper;
        this.energyService = energyService;
        this.userMapper = userMapper;
        this.spiritMapper = spiritMapper;
        this.sessionMapper = sessionMapper;
        this.achievementMapper = achievementMapper;
    }

    public List<ChapterDTO> getUserChapters(Long userId) {
        List<StoryChapter> chapters = chapterMapper.selectListByQuery(
                QueryWrapper.create().orderBy("chapter_number", true));
        List<UserStoryProgress> progress = progressMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));

        Map<Long, UserStoryProgress> progressMap = progress.stream()
                .collect(Collectors.toMap(UserStoryProgress::getChapterId, p -> p));

        return chapters.stream().map(ch -> {
            UserStoryProgress p = progressMap.get(ch.getId());
            boolean unlocked = p != null;
            boolean completed = p != null && Boolean.TRUE.equals(p.getCompleted());
            boolean claimed = p != null && Boolean.TRUE.equals(p.getRewardClaimed());
            return ChapterDTO.builder()
                    .id(ch.getId()).chapterNumber(ch.getChapterNumber()).title(ch.getTitle())
                    .narrative(ch.getNarrative()).npcName(ch.getNpcName())
                    .npcDialogue(ch.getNpcDialogue()).choiceText(ch.getChoiceText())
                    .requirementType(ch.getRequirementType()).requirementValue(ch.getRequirementValue())
                    .rewardEnergy(ch.getRewardEnergy()).displayOrder(ch.getDisplayOrder())
                    .unlocked(unlocked).completed(completed).rewardClaimed(claimed)
                    .build();
        }).collect(Collectors.toList());
    }

    @Transactional
    public void unlockChapter(Long userId, Long chapterId) {
        UserStoryProgress existing = progressMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("chapter_id", chapterId));
        if (existing != null) return; // already unlocked

        UserStoryProgress p = UserStoryProgress.builder()
                .userId(userId).chapterId(chapterId)
                .completed(false).rewardClaimed(false)
                .build();
        try {
            progressMapper.insert(p);
        } catch (org.springframework.dao.DuplicateKeyException e) {
            // Race condition: another request already unlocked this chapter, safe to ignore
        }
    }

    @Transactional
    public void completeChapter(Long userId, Long chapterId) {
        UserStoryProgress p = progressMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("chapter_id", chapterId));
        if (p == null) throw new BusinessException("章节未解锁");
        if (Boolean.TRUE.equals(p.getCompleted())) return;

        p.setCompleted(true);
        p.setCompletedAt(LocalDateTime.now());
        progressMapper.update(p);
    }

    @Transactional
    public void claimReward(Long userId, Long chapterId) {
        UserStoryProgress p = progressMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("chapter_id", chapterId));
        if (p == null) throw new BusinessException("章节未解锁");
        if (!Boolean.TRUE.equals(p.getCompleted())) throw new BusinessException("章节未完成");
        if (Boolean.TRUE.equals(p.getRewardClaimed())) throw new BusinessException("奖励已领取");

        StoryChapter ch = chapterMapper.selectOneById(chapterId);
        if (ch == null) throw new BusinessException("章节不存在");

        if (ch.getRewardEnergy() > 0) {
            energyService.earnEnergy(userId, ch.getRewardEnergy(), "story_chapter", "story_chapter", chapterId);
        }
        p.setRewardClaimed(true);
        progressMapper.update(p);
    }

    public void checkAndUnlockForEvent(Long userId, String type, Number value) {
        List<StoryChapter> chapters = chapterMapper.selectListByQuery(
                QueryWrapper.create().eq("requirement_type", type));

        for (StoryChapter ch : chapters) {
            double val = value.doubleValue();
            double req = ch.getRequirementValue() != null ? ch.getRequirementValue() : 0;
            if (val >= req) {
                unlockChapter(userId, ch.getId());
            }
        }
    }

    @Transactional
    public void checkAllConditions(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) return;

        // Chapter 1: FIRST_SPIRIT - has any spirit
        long spiritCount = spiritMapper.selectCountByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (spiritCount > 0) {
            unlockByType(userId, "FIRST_SPIRIT", 1);
        }

        // Chapters 2-4: COMPLETE_STUDY - has completed any session
        long studyCount = sessionMapper.selectCountByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("status", "COMPLETED"));
        if (studyCount > 0) {
            unlockByType(userId, "COMPLETE_STUDY", 1);
        }

        // Chapter 5: ENERGY_TOTAL - total energy
        if (user.getTotalEnergy() != null && user.getTotalEnergy() >= 200) {
            unlockByType(userId, "ENERGY_TOTAL", 200);
        }

        // Chapter 6: EVOLVE_SPIRIT - check evolution
        List<LearningSpirit> spirits = spiritMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));
        boolean hasEvolved = spirits.stream().anyMatch(s -> s.getCurrentEvolutionStage() > 1);
        if (hasEvolved) {
            unlockByType(userId, "EVOLVE_SPIRIT", 1);
        }

        // Chapters 7-9: ACCURACY - check study records for high accuracy
        Long highAccCount = sessionMapper.selectOneByQueryAs(
                QueryWrapper.create().select("COUNT(*)")
                        .eq("user_id", userId).eq("status", "COMPLETED")
                        .ge("accuracy", 0.8),
                Long.class);
        if (highAccCount != null && highAccCount > 0) {
            unlockByType(userId, "ACCURACY", 80);
        }

        // Chapter 10: AFFECTION
        boolean hasHighAffection = spirits.stream().anyMatch(s -> s.getAffection() != null && s.getAffection() >= 50);
        if (hasHighAffection) {
            unlockByType(userId, "AFFECTION", 50);
        }

        // Chapter 11: STREAK
        if (user.getConsecutiveStudyDays() != null && user.getConsecutiveStudyDays() >= 5) {
            unlockByType(userId, "STREAK", 5);
        }

        // Chapter 12: ACHIEVEMENT_COUNT
        long unlockedCount = achievementMapper.selectCountByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("is_unlocked", true));
        if (unlockedCount >= 3) {
            unlockByType(userId, "ACHIEVEMENT_COUNT", 3);
        }
    }

    private void unlockByType(Long userId, String type, int threshold) {
        List<StoryChapter> chapters = chapterMapper.selectListByQuery(
                QueryWrapper.create().eq("requirement_type", type));
        for (StoryChapter ch : chapters) {
            unlockChapter(userId, ch.getId());
        }
    }
}
