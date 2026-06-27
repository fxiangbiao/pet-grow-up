package com.petgrowup.spirit.entity;

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
@Table("learning_spirit")
public class LearningSpirit {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    @Column("species_id")
    private Long speciesId;

    private String nickname;

    @Column("current_evolution_stage")
    @Builder.Default
    private Integer currentEvolutionStage = 1;

    @Builder.Default
    private Integer experience = 0;

    @Builder.Default
    private Integer happiness = 100;

    @Builder.Default
    private Integer energy = 100;

    @Builder.Default
    private Integer affection = 0;

    @Column("is_active")
    @Builder.Default
    private Boolean isActive = false;

    @Column("personality")
    private String personality;

    @Column("obtained_at")
    private LocalDateTime obtainedAt;
}
