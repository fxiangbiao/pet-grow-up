package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AchievementStatsDTO {
    private List<AchievementStatRowDTO> achievements;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AchievementStatRowDTO {
        private String key;
        private String name;
        private String category;
        private String rarity;
        private long unlockedCount;
        private long totalUsers;
        private double unlockRate;
    }
}
