package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.CreateItemDefDTO;
import com.petgrowup.admin.dto.ItemFilterDTO;
import com.petgrowup.admin.dto.ItemPageDTO;
import com.petgrowup.admin.dto.UpdateItemDefDTO;
import com.petgrowup.admin.service.AdminItemService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.shop.entity.ItemDef;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminItemController {

    private final AdminItemService adminItemService;

    public AdminItemController(AdminItemService adminItemService) {
        this.adminItemService = adminItemService;
    }

    @GetMapping("/items")
    public ApiResponse<ItemPageDTO> listItems(@ModelAttribute ItemFilterDTO filter) {
        return ApiResponse.success(adminItemService.listItems(filter));
    }

    @GetMapping("/items/{id}")
    public ApiResponse<ItemDef> getItem(@PathVariable Long id) {
        return ApiResponse.success(adminItemService.getItem(id));
    }

    @PostMapping("/items")
    public ApiResponse<ItemDef> createItem(@Valid @RequestBody CreateItemDefDTO dto) {
        return ApiResponse.success(adminItemService.createItem(dto));
    }

    @PutMapping("/items/{id}")
    public ApiResponse<ItemDef> updateItem(@PathVariable Long id,
                                           @RequestBody UpdateItemDefDTO dto) {
        return ApiResponse.success(adminItemService.updateItem(id, dto));
    }

    @DeleteMapping("/items/{id}")
    public ApiResponse<Void> deleteItem(@PathVariable Long id) {
        adminItemService.deleteItem(id);
        return ApiResponse.success(null);
    }
}
