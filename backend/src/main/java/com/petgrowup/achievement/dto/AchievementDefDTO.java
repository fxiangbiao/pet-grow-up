package com.petgrowup.achievement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class AchievementDefDTO {
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
}
