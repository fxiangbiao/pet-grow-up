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
public class StudyStatsDTO {
    private List<TimeSeriesPointDTO> dailySessions;
    private List<TimeSeriesPointDTO> dailyActiveUsers;
    private List<TimeSeriesPointDTO> avgAccuracy;
}
