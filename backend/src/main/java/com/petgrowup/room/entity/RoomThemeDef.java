package com.petgrowup.room.entity;

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
@Table("room_theme_def")
public class RoomThemeDef {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("theme_key")
    private String themeKey;

    @Column("name")
    private String name;

    @Column("description")
    private String description;

    @Column("icon_url")
    private String iconUrl;

    @Column("is_default")
    private Boolean isDefault;

    @Column("sort_order")
    private Integer sortOrder;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
