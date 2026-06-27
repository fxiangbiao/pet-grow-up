package com.petgrowup.challenge.controller;

import com.petgrowup.challenge.dto.DailyChallengeDTO;
import com.petgrowup.challenge.service.ChallengeService;
import com.petgrowup.common.response.ApiResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/challenges")
public class ChallengeController {

    private final ChallengeService challengeService;

    public ChallengeController(ChallengeService challengeService) {
        this.challengeService = challengeService;
    }

    @GetMapping("/today")
    public ApiResponse<List<DailyChallengeDTO>> getTodayChallenges(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(challengeService.getTodayChallenges(userId));
    }

    @PostMapping("/{userChallengeId}/claim")
    public ApiResponse<Void> claimReward(@AuthenticationPrincipal Long userId,
                                          @PathVariable Long userChallengeId) {
        challengeService.claimReward(userId, userChallengeId);
        return ApiResponse.success(null);
    }
}
