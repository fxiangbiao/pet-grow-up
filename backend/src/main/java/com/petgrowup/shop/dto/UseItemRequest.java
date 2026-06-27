package com.petgrowup.shop.dto;

import lombok.Data;

@Data
public class UseItemRequest {
    private Long userItemId;
    private Long spiritId;
    private Integer quantity;
}
