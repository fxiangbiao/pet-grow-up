package com.petgrowup.shop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class UserItemDTO {
    private Long id;
    private ItemDefDTO itemDef;
    private Integer quantity;
}
