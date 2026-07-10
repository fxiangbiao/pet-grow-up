package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuestionPageDTO {
    private List<QuestionRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestionRowDTO {
        private Long id;
        private String questionType;
        private Integer difficulty;
        private String questionText;
        private String options;
        private String correctAnswer;
        private String explanation;
        private Integer points;
        private Long knowledgeNodeId;
        private String knowledgeNodeName;
        private String subject;
        private Integer gradeLevel;
        private LocalDateTime createdAt;
    }
}
