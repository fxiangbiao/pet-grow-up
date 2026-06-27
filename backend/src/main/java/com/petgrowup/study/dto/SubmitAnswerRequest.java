package com.petgrowup.study.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SubmitAnswerRequest {
    @NotNull
    private Long sessionId;

    @NotNull
    private Long questionId;

    private String answer;

    private Integer timeSpent;
}
