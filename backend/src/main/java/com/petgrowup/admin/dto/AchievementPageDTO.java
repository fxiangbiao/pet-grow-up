package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AchievementPageDTO {
    private List<AchievementRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AchievementRowDTO {
        private Long id;
        private String achievementKey;
        private String category;
        private String name;
        private String description;
        private String iconUrl;
        private String rarity;
        private String requirementType;
        private Long requirementThreshold;
        private String subject;
        private Long rewardEnergy;
        private String rewardItemKey;
        private String rewardTitle;
        private Integer displayOrder;
        private Boolean isHidden;
        private LocalDateTime createdAt;
    }
}