package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class ItemFilterDTO {
    private String category;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}
