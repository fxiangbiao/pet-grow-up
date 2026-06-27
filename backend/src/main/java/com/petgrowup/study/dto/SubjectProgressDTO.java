package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class SubjectProgressDTO {
    private String subject;
    private Integer worldLevel;
    private Integer totalStars;
    private Integer completedNodes;
    private Integer totalNodes;
    private Double accuracyAverage;
}
