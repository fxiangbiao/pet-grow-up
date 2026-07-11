package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ItemPageDTO {
    private List<ItemRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemRowDTO {
        private Long id;
        private String itemKey;
        private String name;
        private String description;
        private String category;
        private String effectType;
        private Integer effectValue;
        private Long price;
        private String iconUrl;
        private Boolean isConsumable;
        private Boolean isPurchasable;
        private Integer displayOrder;
        private LocalDateTime createdAt;
    }
}
