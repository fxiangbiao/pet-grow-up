package com.petgrowup.achievement.enums;

import lombok.Getter;

@Getter
public enum AchievementRarity {
    COMMON(0, "#9CA3AF"),
    RARE(1, "#3B82F6"),
    EPIC(2, "#8B5CF6"),
    LEGENDARY(3, "#F59E0B");

    private final int level;
    private final String color;

    AchievementRarity(int level, String color) {
        this.level = level;
        this.color = color;
    }
}
