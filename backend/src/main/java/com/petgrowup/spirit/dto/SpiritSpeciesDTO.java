package com.petgrowup.spirit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class SpiritSpeciesDTO {
    private Long id;
    private String speciesKey;
    private String name;
    private String subject;
    private String description;
    private Integer evolutionStage;
    private Long evolvesFromId;
    private Long evolutionEnergyCost;
    private String spriteUrl;
}
