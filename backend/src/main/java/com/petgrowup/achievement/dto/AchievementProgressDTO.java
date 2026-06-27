package com.petgrowup.achievement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class AchievementProgressDTO {
    private List<UserAchievementDTO> unlocked;
    private List<UserAchievementDTO> inProgress;
    private int totalCount;
    private int unlockedCount;
}
