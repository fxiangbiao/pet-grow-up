package com.petgrowup.shop.entity;

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
@Table("item_def")
public class ItemDef {
    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("item_key")
    private String itemKey;

    private String name;
    private String description;
    private String category;
    private String effectType;

    @Column("effect_value")
    private Integer effectValue;

    private Long price;

    @Column("icon_url")
    private String iconUrl;

    @Column("is_consumable")
    private Boolean isConsumable;

    @Column("is_purchasable")
    private Boolean isPurchasable;

    @Column("display_order")
    private Integer displayOrder;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
