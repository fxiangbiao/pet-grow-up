package com.petgrowup.achievement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class AchievementUnlockEvent {
    private Long userId;
    private AchievementDefDTO achievement;
    private Long energyRewarded;
    private String titleGranted;
}
