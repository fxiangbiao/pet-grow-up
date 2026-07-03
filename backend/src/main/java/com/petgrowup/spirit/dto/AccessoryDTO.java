package com.petgrowup.spirit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AccessoryDTO {
    private String slot;
    private String itemKey;
    private String name;
    private String iconUrl;
    private String rarity;
}
