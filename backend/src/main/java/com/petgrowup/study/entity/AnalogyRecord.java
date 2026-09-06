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
@Table("analogy_record")
public class AnalogyRecord {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    @Column("knowledge_node_id")
    private Long knowledgeNodeId;

    @Column("original_question_id")
    private Long originalQuestionId;

    @Column("variant_question_id")
    private Long variantQuestionId;

    @Column("user_answer")
    private String userAnswer;

    @Column("is_correct")
    private Boolean isCorrect;

    @Column("created_at")
    private LocalDateTime createdAt;
}