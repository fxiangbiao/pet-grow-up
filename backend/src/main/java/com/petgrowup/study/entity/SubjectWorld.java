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
@Table("subject_world")
public class SubjectWorld {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    private String subject;

    @Column("world_level")
    private Integer worldLevel;

    @Column("total_stars")
    private Integer totalStars;

    @Column(value = "map_data", isLarge = true)
    private String mapData;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;

    @Column(value = "updated_at", onInsertValue = "NOW()", onUpdateValue = "NOW()")
    private LocalDateTime updatedAt;
}
