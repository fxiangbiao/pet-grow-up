package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UserFilterDTO {
    private String role;
    private String keyword;
    private Integer page = 1;
    private Integer size = 20;
}
