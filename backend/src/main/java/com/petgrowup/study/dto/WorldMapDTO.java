package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class WorldMapDTO {
    private String subject;
    private Integer worldLevel;
    private List<NodeDTO> nodes;
}
