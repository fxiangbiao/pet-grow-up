package com.petgrowup.admin.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class CreateNodeDTO {
    @NotBlank
    private String subject;

    @NotBlank
    private String nodeKey;

    @NotBlank
    private String name;

    private String description;

    @Min(1) @Max(5)
    private Integer difficulty = 1;

    @Min(1) @Max(6)
    private Integer gradeLevel = 1;

    private Long parentNodeId;

    private String prerequisiteNodes;   // JSON array

    private Integer orderIndex = 0;
}
