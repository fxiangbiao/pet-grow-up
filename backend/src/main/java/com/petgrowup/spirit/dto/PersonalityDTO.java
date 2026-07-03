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

    /**
     * Create initial personality dimensions from an archetype.
     * @param type one of: cheerful, gentle, tsundere, brave
     */
    public static PersonalityDTO fromArchetype(String type) {
        return switch (type != null ? type.toLowerCase() : "") {
            case "cheerful" -> PersonalityDTO.builder()
                    .lively(80).shy(30).independent(40).playful(70).gentle(55).brave(45).build();
            case "gentle" -> PersonalityDTO.builder()
                    .lively(35).shy(55).independent(30).playful(35).gentle(85).brave(25).build();
            case "tsundere" -> PersonalityDTO.builder()
                    .lively(40).shy(60).independent(70).playful(40).gentle(40).brave(50).build();
            case "brave" -> PersonalityDTO.builder()
                    .lively(65).shy(20).independent(50).playful(55).gentle(35).brave(85).build();
            default -> defaultPersonality();
        };
    }
}
