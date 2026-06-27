package com.petgrowup.shop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class ItemDefDTO {
    private Long id;
    private String itemKey;
    private String name;
    private String description;
    private String category;
    private String effectType;
    private Integer effectValue;
    private Long price;
    private String iconUrl;
    private Boolean isConsumable;
    private Integer displayOrder;
}
