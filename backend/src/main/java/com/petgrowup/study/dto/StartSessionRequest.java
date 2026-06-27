package com.petgrowup.study.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class StartSessionRequest {
    @NotBlank(message = "Subject is required")
    private String subject;

    @NotBlank(message = "Session type is required")
    private String sessionType;

    @NotNull
    @Min(1) @Max(5)
    private Integer difficultyLevel;

    @NotNull
    private Long knowledgeNodeId;
}
