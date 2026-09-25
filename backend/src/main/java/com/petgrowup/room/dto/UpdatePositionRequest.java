package com.petgrowup.room.dto;

import lombok.Data;

@Data
public class UpdatePositionRequest {
    private Long userItemId;
    /** 历史数据兜底：早期写入的槽位可能没有 userItemId，只能用 itemDefId 定位 */
    private Long itemDefId;
    private Double x;
    private Double y;
}
