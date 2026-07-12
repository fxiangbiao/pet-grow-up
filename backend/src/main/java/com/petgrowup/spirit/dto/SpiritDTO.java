package com.petgrowup.spirit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class SpiritDTO {
    private Long id;
    private SpiritSpeciesDTO species;
    private String nickname;
    private Integer currentEvolutionStage;
    private Integer experience;
    private Integer totalExperienceForNextStage;
    private Integer happiness;
    private Integer energy;
    private Integer affection;
    private Boolean isActive;
    private PersonalityDTO personality;
}
