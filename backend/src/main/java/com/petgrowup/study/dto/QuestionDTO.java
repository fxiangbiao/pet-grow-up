package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class QuestionDTO {
    private Long sessionId;
    private Long questionId;
    private String questionType;
    private String questionText;
    private String options;
    private Integer points;
    private Integer totalQuestions;
    private Integer answeredCount;
}
