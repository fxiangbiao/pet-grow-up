package com.petgrowup.auth.entity;

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
@Table("users")
public class User {

    @Id(keyType = KeyType.Auto)
    private Long id;

    private String username;

    private String email;

    @Column("password_hash")
    private String passwordHash;

    private String nickname;

    @Column("avatar_url")
    private String avatarUrl;

    @Column("current_spirit_id")
    private Long currentSpiritId;

    @Column("total_energy")
    @Builder.Default
    private Long totalEnergy = 0L;

    @Column("current_energy")
    @Builder.Default
    private Long currentEnergy = 0L;

    @Column("consecutive_study_days")
    @Builder.Default
    private Integer consecutiveStudyDays = 0;

    @Column("last_study_date")
    private LocalDate lastStudyDate;

    @Column("last_login_date")
    private LocalDate lastLoginDate;

    @Column("consecutive_login_days")
    @Builder.Default
    private Integer consecutiveLoginDays = 0;

    @Column("daily_reward_claimed_date")
    private LocalDate dailyRewardClaimedDate;

    @Column("role")
    @Builder.Default
    private String role = "STUDENT";

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;

    @Column(value = "updated_at", onInsertValue = "NOW()", onUpdateValue = "NOW()")
    private LocalDateTime updatedAt;
}
