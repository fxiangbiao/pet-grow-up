package com.petgrowup.achievement.checker;

import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.entity.UserAchievement;

import java.util.Map;

public abstract class AbstractAchievementChecker implements AchievementChecker {

    @Override
    public boolean check(Long userId, AchievementDef def, UserAchievement progress, Map<String, Object> context) {
        long currentValue = getCurrentValue(userId, def);
        progress.setCurrentValue(currentValue);
        return currentValue >= def.getRequirementThreshold();
    }
}
