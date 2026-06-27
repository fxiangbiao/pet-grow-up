package com.petgrowup.achievement.checker;

import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.entity.UserAchievement;
import com.petgrowup.achievement.enums.RequirementType;

import java.util.Map;

public interface AchievementChecker {
    RequirementType getType();
    boolean check(Long userId, AchievementDef def, UserAchievement progress, Map<String, Object> context);
    Long getCurrentValue(Long userId, AchievementDef def);
}
