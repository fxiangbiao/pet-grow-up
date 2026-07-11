package com.petgrowup.admin.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateEventDTO {
    private String eventKey;
    private String name;
    private String description;
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