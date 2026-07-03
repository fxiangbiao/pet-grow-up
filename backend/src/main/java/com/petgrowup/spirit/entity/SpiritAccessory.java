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
@Table("spirit_accessory")
public class SpiritAccessory {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("spirit_id")
    private Long spiritId;

    private String slot;

    @Column("item_def_id")
    private Long itemDefId;

    @Column(value = "equipped_at", onInsertValue = "NOW()")
    private LocalDateTime equippedAt;
}
