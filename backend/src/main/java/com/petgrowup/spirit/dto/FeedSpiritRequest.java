package com.petgrowup.spirit.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class FeedSpiritRequest {
    @NotNull(message = "Energy amount is required")
    @Min(value = 1, message = "Minimum feed amount is 1")
    @Max(value = 1000, message = "Maximum feed amount is 1000")
    private Long energyAmount;
}
