package com.petgrowup.admin.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateQuestionDTO {
    private Long knowledgeNodeId;
    private String questionType;
    @Min(1) @Max(5)
    private Integer difficulty;
    private String questionText;
    private String options;
    private String correctAnswer;
    private String explanation;
    @Min(1)
    private Integer points;
}
