package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminEventService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.event.entity.RandomEventDef;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminEventController {

    private final AdminEventService service;

    public AdminEventController(AdminEventService service) {
        this.service = service;
    }

    @GetMapping("/events")
    public ApiResponse<EventPageDTO> list(@ModelAttribute EventFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/events/{id}")
    public ApiResponse<RandomEventDef> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/events")
    public ApiResponse<RandomEventDef> create(@Valid @RequestBody CreateEventDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/events/{id}")
    public ApiResponse<RandomEventDef> update(@PathVariable Long id, @RequestBody UpdateEventDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/events/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}