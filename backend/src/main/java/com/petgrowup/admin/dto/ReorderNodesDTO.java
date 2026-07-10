package com.petgrowup.admin.dto;

import lombok.Data;

import java.util.List;

@Data
public class ReorderNodesDTO {
    private Long parentNodeId;
    private String subject;
    private List<Long> orderedNodeIds;
}
