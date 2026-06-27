package com.petgrowup.shop.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.shop.dto.BuyItemRequest;
import com.petgrowup.shop.dto.ItemDefDTO;
import com.petgrowup.shop.service.ShopService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/shop")
public class ShopController {

    private final ShopService shopService;

    public ShopController(ShopService shopService) {
        this.shopService = shopService;
    }

    @GetMapping("/items")
    public ApiResponse<List<ItemDefDTO>> getItems(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String category) {
        return ApiResponse.success(shopService.getItems(category));
    }

    @PostMapping("/buy")
    public ApiResponse<Void> buyItem(@AuthenticationPrincipal Long userId,
                                      @RequestBody BuyItemRequest request) {
        shopService.buyItem(userId, request);
        return ApiResponse.success(null);
    }
}
