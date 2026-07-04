package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NodeTreeDTO {
    private Long id;
    private String nodeKey;
    private String name;
    private String description;
    private Integer difficulty;
    private Integer gradeLevel;
    private Integer orderIndex;
    private String subject;
    private Long parentNodeId;
    private int questionCount;
    private List<NodeTreeDTO> children;
}
