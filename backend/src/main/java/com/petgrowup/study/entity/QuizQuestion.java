package com.petgrowup.study.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("quiz_question")
public class QuizQuestion {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("knowledge_node_id")
    private Long knowledgeNodeId;

    @Column("question_type")
    private String questionType;

    private Integer difficulty;

    @Column(value = "question_text", isLarge = true)
    private String questionText;

    @Column(value = "options", isLarge = true)
    private String options;

    @Column(value = "correct_answer", isLarge = true)
    private String correctAnswer;

    @Column(isLarge = true)
    private String explanation;

    private Integer points;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
