package com.petgrowup.shop.dto;

import lombok.Data;

@Data
public class BuyItemRequest {
    private Long itemDefId;
    private Integer quantity;
}
