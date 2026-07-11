package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateDailyRewardDTO {
    @NotBlank
    private String rewardKey;

    @NotBlank
    private String name;

    private String description;

    @NotBlank
    private String rewardType;

    private Long rewardValue;
    private String rewardItemKey;

    @NotNull
    private Integer unlockDay;

    private String iconUrl;
    private Integer displayOrder;
}