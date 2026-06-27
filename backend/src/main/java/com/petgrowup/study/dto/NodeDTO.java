package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class NodeDTO {
    private Long nodeId;
    private String name;
    private String description;
    private Integer difficulty;
    private Boolean isUnlocked;
    private Boolean isCompleted;
    private Integer starRating;
}
