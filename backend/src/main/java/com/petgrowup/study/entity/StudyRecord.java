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
@Table("study_record")
public class StudyRecord {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("session_id")
    private Long sessionId;

    @Column("knowledge_node_id")
    private Long knowledgeNodeId;

    @Column("question_id")
    private Long questionId;

    @Column("question_type")
    private String questionType;

    @Column(value = "content", isLarge = true)
    private String content;

    @Column(value = "user_answer", isLarge = true)
    private String userAnswer;

    @Column(value = "correct_answer", isLarge = true)
    private String correctAnswer;

    @Column("is_correct")
    private Boolean isCorrect;

    @Column("time_spent")
    private Integer timeSpent;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
