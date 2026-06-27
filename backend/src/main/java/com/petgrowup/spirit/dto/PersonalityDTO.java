package com.petgrowup.spirit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonalityDTO {
    private Integer lively;
    private Integer shy;
    private Integer independent;
    private Integer playful;
    private Integer gentle;
    private Integer brave;

    public static PersonalityDTO defaultPersonality() {
        return PersonalityDTO.builder()
                .lively(50)
                .shy(50)
                .independent(50)
                .playful(50)
                .gentle(50)
                .brave(50)
                .build();
    }
}
