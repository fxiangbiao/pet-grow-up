package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminDailyRewardService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.daily.entity.DailyRewardDef;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDailyRewardController {

    private final AdminDailyRewardService service;

    public AdminDailyRewardController(AdminDailyRewardService service) {
        this.service = service;
    }

    @GetMapping("/daily-rewards")
    public ApiResponse<DailyRewardPageDTO> list(@ModelAttribute DailyRewardFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/daily-rewards/{id}")
    public ApiResponse<DailyRewardDef> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/daily-rewards")
    public ApiResponse<DailyRewardDef> create(@Valid @RequestBody CreateDailyRewardDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/daily-rewards/{id}")
    public ApiResponse<DailyRewardDef> update(@PathVariable Long id, @RequestBody UpdateDailyRewardDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/daily-rewards/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}