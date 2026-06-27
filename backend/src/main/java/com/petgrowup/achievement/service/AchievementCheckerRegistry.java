package com.petgrowup.achievement.service;

import com.petgrowup.achievement.checker.AchievementChecker;
import com.petgrowup.achievement.enums.RequirementType;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;

@Component
public class AchievementCheckerRegistry {

    private final Map<RequirementType, AchievementChecker> checkerMap = new EnumMap<>(RequirementType.class);

    public AchievementCheckerRegistry(List<AchievementChecker> checkers) {
        for (AchievementChecker checker : checkers) {
            checkerMap.put(checker.getType(), checker);
        }
    }

    public AchievementChecker getChecker(RequirementType type) {
        AchievementChecker checker = checkerMap.get(type);
        if (checker == null) {
            throw new IllegalArgumentException("No checker found for type: " + type);
        }
        return checker;
    }
}
