package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NodeDTO {
    private Long nodeId;
    private String name;
    private String description;
    private Integer difficulty;
    private Boolean isUnlocked;
    private Boolean isCompleted;
    private Integer starRating;
    private Long parentId;
    @Builder.Default
    private List<NodeDTO> children = new java.util.ArrayList<>();
}