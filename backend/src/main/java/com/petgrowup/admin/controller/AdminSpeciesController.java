package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminSpeciesService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.spirit.entity.SpiritSpecies;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminSpeciesController {

    private final AdminSpeciesService service;

    public AdminSpeciesController(AdminSpeciesService service) {
        this.service = service;
    }

    @GetMapping("/species")
    public ApiResponse<SpeciesPageDTO> list(@ModelAttribute SpeciesFilterDTO filter) {
        return ApiResponse.success(service.list(filter));
    }

    @GetMapping("/species/{id}")
    public ApiResponse<SpiritSpecies> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping("/species")
    public ApiResponse<SpiritSpecies> create(@Valid @RequestBody CreateSpeciesDTO dto) {
        return ApiResponse.success(service.create(dto));
    }

    @PutMapping("/species/{id}")
    public ApiResponse<SpiritSpecies> update(@PathVariable Long id, @RequestBody UpdateSpeciesDTO dto) {
        return ApiResponse.success(service.update(id, dto));
    }

    @DeleteMapping("/species/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }
}