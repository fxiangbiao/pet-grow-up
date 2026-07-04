package com.petgrowup.daily.entity;

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
@Table("daily_reward_def")
public class DailyRewardDef {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("reward_key")
    private String rewardKey;

    private String name;

    private String description;

    @Column("reward_type")
    private String rewardType;

    @Column("reward_value")
    private Long rewardValue;

    @Column("reward_item_key")
    private String rewardItemKey;

    @Column("unlock_day")
    private Integer unlockDay;

    @Column("icon_url")
    private String iconUrl;

    @Column("display_order")
    private Integer displayOrder;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
