package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.AchievementStatsDTO;
import com.petgrowup.admin.dto.EnergyStatsDTO;
import com.petgrowup.admin.dto.OverviewDTO;
import com.petgrowup.admin.dto.StudyStatsDTO;
import com.petgrowup.admin.service.AdminStatisticsService;
import com.petgrowup.common.response.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminStatisticsController {

    private final AdminStatisticsService adminStatisticsService;

    public AdminStatisticsController(AdminStatisticsService adminStatisticsService) {
        this.adminStatisticsService = adminStatisticsService;
    }

    @GetMapping("/statistics/overview")
    public ApiResponse<OverviewDTO> getOverview() {
        return ApiResponse.success(adminStatisticsService.getOverview());
    }

    @GetMapping("/statistics/study")
    public ApiResponse<StudyStatsDTO> getStudyStats(@RequestParam(defaultValue = "7") int days) {
        return ApiResponse.success(adminStatisticsService.getStudyStats(days));
    }

    @GetMapping("/statistics/energy")
    public ApiResponse<EnergyStatsDTO> getEnergyStats(@RequestParam(defaultValue = "7") int days) {
        return ApiResponse.success(adminStatisticsService.getEnergyStats(days));
    }

    @GetMapping("/statistics/achievements")
    public ApiResponse<AchievementStatsDTO> getAchievementStats() {
        return ApiResponse.success(adminStatisticsService.getAchievementStats());
    }
}
