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
@Table("learning_weakness")
public class LearningWeakness {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    @Column("knowledge_node_id")
    private Long knowledgeNodeId;

    private String subject;

    @Builder.Default
    private Integer wrongCount = 1;

    @Column("last_wrong_at")
    @Builder.Default
    private LocalDateTime lastWrongAt = LocalDateTime.now();

    @Builder.Default
    private Integer masteryLevel = 0;
}
