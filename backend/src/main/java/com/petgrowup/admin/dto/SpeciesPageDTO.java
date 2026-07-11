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
public class SpeciesPageDTO {
    private List<SpeciesRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SpeciesRowDTO {
        private Long id;
        private String speciesKey;
        private String name;
        private String subject;
        private String description;
        private Integer evolutionStage;
        private Long evolvesFromId;
        private Long evolutionEnergyCost;
        private Integer baseAffection;
        private String spriteUrl;
        private String animationData;
        private LocalDateTime createdAt;
    }
}