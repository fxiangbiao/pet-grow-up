package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OverviewDTO {
    private long totalUsers;
    private long totalStudents;
    private long totalAdmins;
    private long totalQuestions;
    private long totalStudySessions;
    private long totalEnergyEarned;
    private long totalEnergySpent;
    private long todayActiveUsers;
}
