package com.petgrowup.event.entity;

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
@Table("random_event_def")
public class RandomEventDef {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("event_key")
    private String eventKey;

    private String name;

    private String description;

    @Column("event_type")
    private String eventType;

    @Column("trigger_chance")
    private BigDecimal triggerChance;

    @Column("min_accuracy")
    private BigDecimal minAccuracy;

    @Column("min_streak")
    private Integer minStreak;

    @Column("reward_energy")
    private Long rewardEnergy;

    @Column("reward_item_key")
    private String rewardItemKey;

    @Column("reward_affection")
    private Integer rewardAffection;

    @Column("display_text")
    private String displayText;

    @Column("icon_url")
    private String iconUrl;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
