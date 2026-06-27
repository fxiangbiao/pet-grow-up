package com.petgrowup.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class EnergyBalanceDTO {
    private Long currentBalance;
    private Long todayEarned;
    private Long todaySpent;
    private Long weeklyTotal;
}
