package com.petgrowup.achievement.entity;

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
@Table("user_achievement")
public class UserAchievement {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    @Column("achievement_def_id")
    private Long achievementDefId;

    @Column("current_value")
    private Long currentValue;

    @Column("is_unlocked")
    private Boolean isUnlocked;

    @Column("unlocked_at")
    private LocalDateTime unlockedAt;

    private Boolean notified;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;

    @Column(value = "updated_at", onInsertValue = "NOW()", onUpdateValue = "NOW()")
    private LocalDateTime updatedAt;
}
