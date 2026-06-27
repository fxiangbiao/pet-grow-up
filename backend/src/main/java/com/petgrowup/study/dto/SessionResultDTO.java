package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class SessionResultDTO {
    private Long sessionId;
    private Integer totalQuestions;
    private Integer correctAnswers;
    private Double accuracy;
    private Long energyEarned;
    private Boolean streakMaintained;
    private String spiritReaction;
    private Integer maxCombo;
    private Boolean bossDefeated;
    private Long comboBonusEnergy;
}
