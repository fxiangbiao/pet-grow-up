package com.petgrowup.room.dto;

import lombok.Data;

@Data
public class UpdatePositionRequest {
    private Long userItemId;
    private Double x;
    private Double y;
}
