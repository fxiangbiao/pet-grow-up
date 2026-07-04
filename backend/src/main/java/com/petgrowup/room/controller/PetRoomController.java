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

    @DeleteMapping("/remove")
    public ApiResponse<PetRoomDTO> removeItem(@AuthenticationPrincipal Long userId,
                                               @RequestParam Long userItemId) {
        return ApiResponse.success(petRoomService.removeItem(userId, userItemId));
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
