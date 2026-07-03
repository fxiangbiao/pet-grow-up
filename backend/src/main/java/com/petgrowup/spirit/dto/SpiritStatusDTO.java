package com.petgrowup.spirit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpiritStatusDTO {
    /** 0=normal, 1=dim (1-2 days), 2=sleeping (3+ days) */
    private int dormancyLevel;
    private LocalDate lastStudyDate;
    private long daysSinceLastStudy;
    private String personalityType;
}
