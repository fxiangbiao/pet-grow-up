package com.petgrowup.room.dto;

import com.petgrowup.spirit.dto.SpiritDTO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class PetRoomDTO {
    private Long id;
    private String roomStyle;
    private String themeName;
    private String themeIcon;
    private List<PlacedItemDTO> furniture;
    private SpiritDTO activeSpirit;

    @Data
    @Builder
    @AllArgsConstructor
    public static class PlacedItemDTO {
        private Long itemDefId;
        private Long userItemId;
        private String itemKey;
        private String name;
        private String iconUrl;
        private String category;
        private Double x;
        private Double y;
    }
}
