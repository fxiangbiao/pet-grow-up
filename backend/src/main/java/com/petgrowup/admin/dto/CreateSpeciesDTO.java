package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateSpeciesDTO {
    @NotBlank
    private String speciesKey;

    @NotBlank
    private String name;

    @NotBlank
    private String subject;

    private String description;
    private Integer evolutionStage;
    private Long evolvesFromId;
    private Long evolutionEnergyCost;
    private Integer baseAffection;

    private String spriteUrl;
    private String animationData;
}