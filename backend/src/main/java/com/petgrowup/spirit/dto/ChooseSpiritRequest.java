package com.petgrowup.spirit.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ChooseSpiritRequest {
    @NotNull(message = "Species ID is required")
    private Long speciesId;

    @NotBlank(message = "Nickname is required")
    private String nickname;
}
