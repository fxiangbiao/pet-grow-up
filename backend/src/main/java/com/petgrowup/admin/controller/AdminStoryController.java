package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminStoryService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.story.entity.StoryChapter;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 剧情章节管理（管理后台）。
 *
 * 说明：AdminStoryService / StoryFilterDTO / CreateStoryDTO / UpdateStoryDTO 早已存在，
 * 但一直缺少这个控制器，导致前端 /admin/stories 调用的 /api/v1/admin/stories 无人处理，
 * Spring Boot 3.2 抛出的 NoResourceFoundException 被 GlobalExceptionHandler 的
 * 兜底 @ExceptionHandler(Exception.class) 接走，对外表现成 500「服务器内部错误」。
 */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminStoryController {

    private final AdminStoryService service;

    public AdminStoryController(AdminStoryService service) {
        this.service = service;
    }

    @GetMapping("/stories")
    public ApiResponse<StoryPageDTO> list(@ModelAttribute StoryFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/stories/{id}")
    public ApiResponse<StoryChapter> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/stories")
    public ApiResponse<StoryChapter> create(@Valid @RequestBody CreateStoryDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/stories/{id}")
    public ApiResponse<StoryChapter> update(@PathVariable Long id, @RequestBody UpdateStoryDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/stories/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}
