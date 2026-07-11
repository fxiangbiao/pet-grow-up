package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class SpeciesFilterDTO {
    private String subject;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}