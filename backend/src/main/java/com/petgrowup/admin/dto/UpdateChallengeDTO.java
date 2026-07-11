package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateChallengeDTO {
    private String challengeType;
    private String description;
    private Integer targetValue;
    private Long rewardEnergy;
    private String iconUrl;
    private Integer displayOrder;
}