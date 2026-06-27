package com.petgrowup.achievement.controller;

import com.petgrowup.achievement.dto.AchievementProgressDTO;
import com.petgrowup.achievement.dto.UserAchievementDTO;
import com.petgrowup.achievement.service.AchievementService;
import com.petgrowup.common.response.ApiResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/achievements")
public class AchievementController {

    private final AchievementService achievementService;

    public AchievementController(AchievementService achievementService) {
        this.achievementService = achievementService;
    }

    @GetMapping
    public ApiResponse<AchievementProgressDTO> getUserAchievements(@AuthenticationPrincipal Long userId) {
        achievementService.initializeUserAchievements(userId);
        return ApiResponse.success(achievementService.getUserAchievements(userId));
    }

    @PostMapping("/{userAchievementId}/notified")
    public ApiResponse<Void> markNotified(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long userAchievementId) {
        achievementService.markNotified(userId, userAchievementId);
        return ApiResponse.success(null);
    }
}
