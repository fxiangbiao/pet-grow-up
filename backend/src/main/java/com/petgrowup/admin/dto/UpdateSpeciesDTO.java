package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateSpeciesDTO {
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
}