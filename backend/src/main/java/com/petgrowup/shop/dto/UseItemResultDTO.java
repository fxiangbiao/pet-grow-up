package com.petgrowup.shop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class UseItemResultDTO {
    private int happinessChange;
    private int energyChange;
    private int affectionChange;
    private String itemName;
    private int quantityUsed;
}
