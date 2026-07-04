package com.petgrowup.event.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class RandomEventDTO {
    private String eventKey;
    private String name;
    private String description;
    private String eventType;
    private String iconUrl;
    private String displayText;
    private Long bonusEnergy;
    private String rewardItemName;
    private int affectionGained;
    private boolean isDoubleReward;
}
