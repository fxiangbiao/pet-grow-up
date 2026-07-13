package com.petgrowup.study.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.dto.SubjectProgressDTO;
import com.petgrowup.study.dto.WorldMapDTO;
import com.petgrowup.study.service.SubjectWorldService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/study")
public class SubjectWorldController {

    private final SubjectWorldService worldService;

    public SubjectWorldController(SubjectWorldService worldService) {
        this.worldService = worldService;
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
}
