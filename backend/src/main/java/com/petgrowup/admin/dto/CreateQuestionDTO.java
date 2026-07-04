package com.petgrowup.admin.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class CreateQuestionDTO {
    @NotNull
    private Long knowledgeNodeId;

    @NotBlank
    private String questionType;

    @Min(1) @Max(5)
    private Integer difficulty = 1;

    @NotBlank
    private String questionText;

    private String options;        // JSON string

    @NotBlank
    private String correctAnswer;

    private String explanation;

    @Min(1)
    private Integer points = 10;
}
