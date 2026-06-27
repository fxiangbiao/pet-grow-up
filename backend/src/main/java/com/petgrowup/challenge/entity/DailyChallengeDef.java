package com.petgrowup.challenge.entity;

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
@Table("daily_challenge_def")
public class DailyChallengeDef {
    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("challenge_type")
    private String challengeType;

    private String description;

    @Column("target_value")
    private Integer targetValue;

    @Column("reward_energy")
    private Long rewardEnergy;

    @Column("icon_url")
    private String iconUrl;

    @Column("display_order")
    private Integer displayOrder;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
