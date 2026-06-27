package com.petgrowup.challenge.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class DailyChallengeDTO {
    private Long id;
    private String challengeType;
    private String description;
    private Integer targetValue;
    private Long rewardEnergy;
    private String iconUrl;
    private Integer displayOrder;
    private Integer progress;
    private Boolean completed;
    private Boolean rewardClaimed;
}
