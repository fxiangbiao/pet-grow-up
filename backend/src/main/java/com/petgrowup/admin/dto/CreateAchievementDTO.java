package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateAchievementDTO {
    @NotBlank
    private String achievementKey;

    @NotBlank
    private String category;

    @NotBlank
    private String name;

    private String description;
    private String iconUrl;

    @NotBlank
    private String rarity;

    @NotBlank
    private String requirementType;

    @NotNull
    private Long requirementThreshold;

    private String subject;
    private Long rewardEnergy;
    private String rewardItemKey;
    private String rewardTitle;
    private Integer displayOrder;
    private Boolean isHidden;
}