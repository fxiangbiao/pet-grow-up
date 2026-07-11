package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateEventDTO {
    @NotBlank
    private String eventKey;

    @NotBlank
    private String name;

    private String description;

    @NotBlank
    private String eventType;

    private BigDecimal triggerChance;
    private BigDecimal minAccuracy;
    private Integer minStreak;
    private Long rewardEnergy;
    private String rewardItemKey;
    private Integer rewardAffection;
    private String displayText;
    private String iconUrl;
}