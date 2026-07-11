package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateItemDefDTO {
    private String itemKey;
    private String name;
    private String description;
    private String category;
    private String effectType;
    private Integer effectValue;
    private Long price;
    private String iconUrl;
    private Boolean isConsumable;
    private Boolean isPurchasable;
    private Integer displayOrder;
}
