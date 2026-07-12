package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class WeaknessDTO {
    private Long knowledgeNodeId;
    private String knowledgeNodeName;
    private String subject;
    private Integer wrongCount;
    private Integer masteryLevel;
    private String lastWrongAt;
}
