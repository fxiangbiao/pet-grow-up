package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class QuestionFilterDTO {
    private String subject;
    private Integer gradeLevel;
    private String questionType;
    private Long knowledgeNodeId;
    private Integer difficulty;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}
