package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateNodeDTO {
    private String nodeKey;
    private String name;
    private String description;
    private Integer difficulty;
    private Integer gradeLevel;
    private Long parentNodeId;
    private String prerequisiteNodes;
    private Integer orderIndex;
}
