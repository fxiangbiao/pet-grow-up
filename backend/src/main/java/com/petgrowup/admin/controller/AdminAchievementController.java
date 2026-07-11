package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminAchievementService;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.common.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAchievementController {

    private final AdminAchievementService service;

    public AdminAchievementController(AdminAchievementService service) {
        this.service = service;
    }

    @GetMapping("/achievements")
    public ApiResponse<AchievementPageDTO> list(@ModelAttribute AchievementFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/achievements/{id}")
    public ApiResponse<AchievementDef> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/achievements")
    public ApiResponse<AchievementDef> create(@Valid @RequestBody CreateAchievementDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/achievements/{id}")
    public ApiResponse<AchievementDef> update(@PathVariable Long id, @RequestBody UpdateAchievementDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/achievements/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}