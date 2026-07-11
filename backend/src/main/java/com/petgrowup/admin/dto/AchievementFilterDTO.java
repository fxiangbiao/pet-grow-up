package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class AchievementFilterDTO {
    private String category;
    private String rarity;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}