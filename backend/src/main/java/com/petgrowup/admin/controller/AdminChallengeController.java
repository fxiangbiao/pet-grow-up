package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminChallengeService;
import com.petgrowup.challenge.entity.DailyChallengeDef;
import com.petgrowup.common.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminChallengeController {

    private final AdminChallengeService service;

    public AdminChallengeController(AdminChallengeService service) {
        this.service = service;
    }

    @GetMapping("/challenges")
    public ApiResponse<ChallengePageDTO> list(@ModelAttribute ChallengeFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/challenges/{id}")
    public ApiResponse<DailyChallengeDef> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/challenges")
    public ApiResponse<DailyChallengeDef> create(@Valid @RequestBody CreateChallengeDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/challenges/{id}")
    public ApiResponse<DailyChallengeDef> update(@PathVariable Long id, @RequestBody UpdateChallengeDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/challenges/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}