package com.petgrowup.social.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.social.dto.LeaderboardEntryDTO;
import com.petgrowup.social.service.LeaderboardService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/social/leaderboard")
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    public LeaderboardController(LeaderboardService leaderboardService) {
        this.leaderboardService = leaderboardService;
    }

    @GetMapping
    public ApiResponse<List<LeaderboardEntryDTO>> getLeaderboard(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "total_energy") String type,
            @RequestParam(defaultValue = "20") int limit) {
        return ApiResponse.success(leaderboardService.getLeaderboard(type, limit, userId));
    }
}
