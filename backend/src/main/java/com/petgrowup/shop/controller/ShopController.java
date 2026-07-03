package com.petgrowup.shop.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.shop.dto.BuyItemRequest;
import com.petgrowup.shop.dto.ItemDefDTO;
import com.petgrowup.shop.service.GachaService;
import com.petgrowup.shop.service.ShopService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/shop")
public class ShopController {

    private final ShopService shopService;
    private final GachaService gachaService;

    public ShopController(ShopService shopService, GachaService gachaService) {
        this.shopService = shopService;
        this.gachaService = gachaService;
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

    // ── Sprint E: Gacha ──
    @PostMapping("/gacha/draw")
    public ApiResponse<Map<String, Object>> drawGacha(
            @AuthenticationPrincipal Long userId,
            @RequestBody Map<String, Object> body) {
        boolean free = body != null && Boolean.TRUE.equals(body.get("free"));
        return ApiResponse.success(gachaService.draw(userId, free));
    }
}
