package com.petgrowup.story.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.story.dto.ChapterDTO;
import com.petgrowup.story.service.StoryService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/story")
public class StoryController {

    private final StoryService storyService;

    public StoryController(StoryService storyService) {
        this.storyService = storyService;
    }

    @GetMapping("/chapters")
    public ApiResponse<List<ChapterDTO>> getChapters(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(storyService.getUserChapters(userId));
    }

    @PostMapping("/chapters/{chapterId}/complete")
    public ApiResponse<Void> completeChapter(@AuthenticationPrincipal Long userId,
                                              @PathVariable Long chapterId) {
        storyService.completeChapter(userId, chapterId);
        return ApiResponse.success(null);
    }

    @PostMapping("/chapters/{chapterId}/claim")
    public ApiResponse<Void> claimReward(@AuthenticationPrincipal Long userId,
                                          @PathVariable Long chapterId) {
        storyService.claimReward(userId, chapterId);
        return ApiResponse.success(null);
    }

    @PostMapping("/check")
    public ApiResponse<Void> checkAll(@AuthenticationPrincipal Long userId) {
        storyService.checkAllConditions(userId);
        return ApiResponse.success(null);
    }
}
