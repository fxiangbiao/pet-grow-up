package com.petgrowup.challenge.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("user_challenge")
public class UserChallenge {
    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    @Column("challenge_def_id")
    private Long challengeDefId;

    @Column("challenge_date")
    private LocalDate challengeDate;

    private Integer progress;

    private Boolean completed;

    @Column("reward_claimed")
    private Boolean rewardClaimed;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;

    @Column(value = "updated_at", onInsertValue = "NOW()", onUpdateValue = "NOW()")
    private LocalDateTime updatedAt;
}
