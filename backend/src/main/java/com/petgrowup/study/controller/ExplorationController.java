package com.petgrowup.study.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.dto.*;
import com.petgrowup.study.service.ExplorationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/exploration")
public class ExplorationController {

    private final ExplorationService explorationService;

    public ExplorationController(ExplorationService explorationService) {
        this.explorationService = explorationService;
    }

    @PostMapping("/sessions/start")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<QuestionDTO> startSession(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody StartSessionRequest request) {
        return ApiResponse.success(explorationService.startSession(userId, request));
    }

    @PostMapping("/sessions/{id}/submit")
    public ApiResponse<AnswerResultDTO> submitAnswer(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long id,
            @Valid @RequestBody SubmitAnswerRequest request) {
        request.setSessionId(id);
        return ApiResponse.success(explorationService.submitAnswer(userId, request));
    }

    @GetMapping("/sessions/{id}/result")
    public ApiResponse<SessionResultDTO> getSessionResult(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int maxCombo,
            @RequestParam(defaultValue = "false") boolean bossDefeated) {
        return ApiResponse.success(explorationService.getSessionResult(id, userId, maxCombo, bossDefeated));
    }
}
