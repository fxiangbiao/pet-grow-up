package com.petgrowup.study.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("study_session")
public class StudySession {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    private String subject;

    @Column("session_type")
    private String sessionType;

    private String status;

    @Column("difficulty_level")
    private Integer difficultyLevel;

    @Column("base_reward")
    private Long baseReward;

    @Column("total_questions")
    private Integer totalQuestions;

    @Column("correct_answers")
    private Integer correctAnswers;

    private BigDecimal accuracy;

    @Column("actual_duration")
    private Integer actualDuration;

    @Column("expected_duration")
    private Integer expectedDuration;

    @Column("energy_earned")
    private Long energyEarned;

    @Column("streak_at_time")
    private Integer streakAtTime;

    @Column("question_order")
    private String questionOrder;

    @Column("current_combo")
    private Integer currentCombo;

    @Column("max_combo")
    private Integer maxCombo;

    @Column("boss_defeated")
    private Boolean bossDefeated;

    @Column("started_at")
    private LocalDateTime startedAt;

    @Column("completed_at")
    private LocalDateTime completedAt;

    @Column("random_event_key")
    private String randomEventKey;

    @Column("random_event_bonus_energy")
    @Builder.Default
    private Long randomEventBonusEnergy = 0L;
}
