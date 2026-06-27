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
@Table("achievement_def")
public class AchievementDef {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("achievement_key")
    private String achievementKey;

    private String category;

    private String name;

    @Column(isLarge = true)
    private String description;

    @Column("icon_url")
    private String iconUrl;

    private String rarity;

    @Column("requirement_type")
    private String requirementType;

    @Column("requirement_threshold")
    private Long requirementThreshold;

    private String subject;

    @Column("reward_energy")
    private Long rewardEnergy;

    @Column("reward_item_key")
    private String rewardItemKey;

    @Column("reward_title")
    private String rewardTitle;

    @Column("display_order")
    private Integer displayOrder;

    @Column("is_hidden")
    private Boolean isHidden;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
