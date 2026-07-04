package com.petgrowup.daily.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.daily.dto.ClaimResultDTO;
import com.petgrowup.daily.dto.DailyRewardStatusDTO;
import com.petgrowup.daily.service.DailyRewardService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/daily-reward")
public class DailyRewardController {

    private final DailyRewardService dailyRewardService;

    public DailyRewardController(DailyRewardService dailyRewardService) {
        this.dailyRewardService = dailyRewardService;
    }

    @GetMapping("/status")
    public ApiResponse<DailyRewardStatusDTO> getStatus(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(dailyRewardService.getStatus(userId));
    }

    @PostMapping("/claim")
    public ApiResponse<ClaimResultDTO> claim(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(dailyRewardService.claim(userId));
    }
}
