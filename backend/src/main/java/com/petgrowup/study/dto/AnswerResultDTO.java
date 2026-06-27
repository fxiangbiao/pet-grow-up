package com.petgrowup.study.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class AnswerResultDTO {
    private Boolean isCorrect;
    private String correctAnswer;
    private String explanation;
    private Integer pointsEarned;
    private Boolean isSessionComplete;
    private Boolean isLastQuestion;
    private QuestionDTO nextQuestion;
}
