package com.petgrowup.study.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.dto.WeaknessDTO;
import com.petgrowup.study.service.WeaknessService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/study/weaknesses")
public class WeaknessController {

    private final WeaknessService weaknessService;

    public WeaknessController(WeaknessService weaknessService) {
        this.weaknessService = weaknessService;
    }

    @GetMapping
    public ApiResponse<List<WeaknessDTO>> getWeaknesses(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "10") int limit) {
        return ApiResponse.success(weaknessService.getWeaknesses(userId, limit));
    }
}
