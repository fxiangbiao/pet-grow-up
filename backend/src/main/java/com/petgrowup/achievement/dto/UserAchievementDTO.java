package com.petgrowup.achievement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
public class UserAchievementDTO {
    private Long id;
    private Long achievementDefId;
    private AchievementDefDTO definition;
    private Long currentValue;
    private Boolean isUnlocked;
    private LocalDateTime unlockedAt;
    private Boolean notified;
}
