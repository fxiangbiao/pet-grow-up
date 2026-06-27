package com.petgrowup.shop.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.shop.dto.UseItemRequest;
import com.petgrowup.shop.dto.UseItemResultDTO;
import com.petgrowup.shop.dto.UserItemDTO;
import com.petgrowup.shop.service.InventoryService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inventory")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping
    public ApiResponse<List<UserItemDTO>> getInventory(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(inventoryService.getInventory(userId));
    }

    @PostMapping("/use")
    public ApiResponse<UseItemResultDTO> useItem(@AuthenticationPrincipal Long userId,
                                                  @RequestBody UseItemRequest request) {
        return ApiResponse.success(inventoryService.useItem(userId, request));
    }
}
