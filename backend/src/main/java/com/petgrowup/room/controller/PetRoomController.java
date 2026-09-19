package com.petgrowup.room.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.room.dto.*;
import com.petgrowup.room.dto.PetRoomDTO.PlacedItemDTO;
import com.petgrowup.room.service.PetRoomService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/pet-room")
public class PetRoomController {

    private final PetRoomService petRoomService;

    public PetRoomController(PetRoomService petRoomService) {
        this.petRoomService = petRoomService;
    }

    @GetMapping
    public ApiResponse<PetRoomDTO> getRoom(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(petRoomService.getRoom(userId));
    }

    @PostMapping("/place")
    public ApiResponse<PetRoomDTO> placeItem(@AuthenticationPrincipal Long userId,
                                              @RequestBody PlaceItemRequest request) {
        return ApiResponse.success(petRoomService.placeItem(userId, request));
    }

    /**
     * 移除屋内装饰。
     * userItemId / itemDefId 至少给一个：优先用 userItemId 精确匹配；
     * 历史数据里的条目可能没有 userItemId，此时用 itemDefId 兜底。
     * 一个都没匹配到会报错（不再静默返回原样，避免前端误报"已移除"）。
     */
    @DeleteMapping("/remove")
    public ApiResponse<PetRoomDTO> removeItem(@AuthenticationPrincipal Long userId,
                                               @RequestParam(required = false) Long userItemId,
                                               @RequestParam(required = false) Long itemDefId) {
        return ApiResponse.success(petRoomService.removeItem(userId, userItemId, itemDefId));
    }

    @PutMapping("/position")
    public ApiResponse<PetRoomDTO> updatePosition(@AuthenticationPrincipal Long userId,
                                                   @RequestBody UpdatePositionRequest request) {
        return ApiResponse.success(petRoomService.updatePosition(userId, request));
    }

    @PutMapping("/theme")
    public ApiResponse<PetRoomDTO> changeTheme(@AuthenticationPrincipal Long userId,
                                                @RequestBody ChangeThemeRequest request) {
        return ApiResponse.success(petRoomService.changeTheme(userId, request.getThemeKey()));
    }

    @GetMapping("/available-decorations")
    public ApiResponse<List<PlacedItemDTO>> getAvailableDecorations(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(petRoomService.getAvailableDecorations(userId));
    }
}
