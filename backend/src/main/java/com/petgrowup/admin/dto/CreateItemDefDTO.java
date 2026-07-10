package com.petgrowup.admin.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateItemDefDTO {
    @NotBlank
    private String itemKey;

    @NotBlank
    private String name;

    private String description;

    @NotBlank
    private String category;

    private String effectType;

    @Min(0)
    private Integer effectValue = 0;

    @Min(0)
    private Long price = 0L;

    private String iconUrl;

    private Boolean isConsumable = true;

    private Boolean isPurchasable = true;

    private Integer displayOrder = 0;
}
