package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateChallengeDTO {
    @NotBlank
    private String challengeType;

    @NotBlank
    private String description;

    private Integer targetValue;
    private Long rewardEnergy;
    private String iconUrl;
    private Integer displayOrder;
}