package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateAchievementDTO {
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