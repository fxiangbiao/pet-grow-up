package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class EventFilterDTO {
    private String eventType;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}