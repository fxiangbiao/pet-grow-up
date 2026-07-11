package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EnergyStatsDTO {
    private List<TimeSeriesPointDTO> dailyEarned;
    private List<TimeSeriesPointDTO> dailySpent;
    private List<SourceBreakdownDTO> bySource;
}
