package com.petgrowup.study.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.dto.SubjectProgressDTO;
import com.petgrowup.study.dto.WorldMapDTO;
import com.petgrowup.study.service.SubjectWorldService;
import com.petgrowup.study.service.QuestionGeneratorService;
import com.petgrowup.study.service.ExplanationAssessmentService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/study")
public class SubjectWorldController {

    private final SubjectWorldService worldService;
    private final QuestionGeneratorService questionGeneratorService;
    private final ExplanationAssessmentService explanationAssessmentService;

    public SubjectWorldController(SubjectWorldService worldService, QuestionGeneratorService questionGeneratorService, ExplanationAssessmentService explanationAssessmentService) {
        this.worldService = worldService;
        this.questionGeneratorService = questionGeneratorService;
        this.explanationAssessmentService = explanationAssessmentService;
    }

    @GetMapping("/worlds/{subject}")
    public ApiResponse<WorldMapDTO> getWorldMap(
            @AuthenticationPrincipal Long userId,
            @PathVariable String subject) {
        return ApiResponse.success(worldService.getWorldMap(userId, subject));
    }

    @GetMapping("/subjects")
    public ApiResponse<List<SubjectProgressDTO>> getSubjectsProgress(
            @AuthenticationPrincipal Long userId) {
        return ApiResponse.success(worldService.getProgressList(userId));
    }

    @GetMapping("/nodes/{nodeId}/teaching")
    public ApiResponse<Object> getTeachingContent(@PathVariable Long nodeId) {
        return ApiResponse.success(worldService.getTeachingContent(nodeId));
    }

    @GetMapping("/nodes/{nodeId}/generate-variant")
    public ApiResponse<Map<String, Object>> generateVariant(
            @PathVariable Long nodeId,
            @RequestParam Long originalQuestionId) {
        Map<String, Object> variant = questionGeneratorService.generateVariant(nodeId, originalQuestionId);
        if (variant == null) {
            return ApiResponse.error(404, "No variant available");
        }
        return ApiResponse.success(variant);
    }

    @PostMapping("/nodes/{nodeId}/explain")
    public ApiResponse<java.util.Map<String, Object>> assessExplanation(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long nodeId,
            @RequestBody java.util.Map<String, String> body) {
        String text = body.get("text");
        java.util.Map<String, Object> result = explanationAssessmentService.assessExplanation(nodeId, text);
        if (result == null) {
            return ApiResponse.error(404, "Knowledge node not found");
        }
        return ApiResponse.success(result);
    }
}
