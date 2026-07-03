package com.petgrowup.spirit.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.spirit.dto.*;
import com.petgrowup.spirit.service.SpiritService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/spirits")
public class SpiritController {

    private final SpiritService spiritService;

    public SpiritController(SpiritService spiritService) {
        this.spiritService = spiritService;
    }

    @GetMapping("/species")
    public ApiResponse<List<SpiritSpeciesDTO>> getAvailableSpecies() {
        return ApiResponse.success(spiritService.getAvailableSpecies());
    }

    @GetMapping
    public ApiResponse<List<SpiritDTO>> getUserSpirits(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(spiritService.getUserSpirits(userId));
    }

    @GetMapping("/{id}")
    public ApiResponse<SpiritDTO> getSpiritDetail(@PathVariable Long id) {
        return ApiResponse.success(spiritService.getSpiritDetail(id));
    }

    @GetMapping("/status")
    public ApiResponse<SpiritStatusDTO> getSpiritStatus(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(spiritService.getSpiritStatus(userId));
    }

    // ── Sprint E: Accessory management ──

    @GetMapping("/{id}/accessories")
    public ApiResponse<List<AccessoryDTO>> getAccessories(@PathVariable Long id) {
        return ApiResponse.success(spiritService.getEquippedAccessories(id));
    }

    @PutMapping("/{id}/accessories")
    public ApiResponse<List<AccessoryDTO>> equipAccessory(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        String slot = (String) body.get("slot");
        Object itemIdObj = body.get("itemDefId");
        if (itemIdObj == null) {
            return ApiResponse.success(spiritService.unequipAccessory(id, slot));
        }
        Long itemDefId = Long.valueOf(itemIdObj.toString());
        return ApiResponse.success(spiritService.equipAccessory(id, slot, itemDefId));
    }

    @PostMapping("/choose")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<SpiritDTO> chooseStarter(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody ChooseSpiritRequest request) {
        return ApiResponse.success(spiritService.chooseStarterSpirit(userId, request));
    }

    @PostMapping("/{id}/feed")
    public ApiResponse<SpiritDTO> feedSpirit(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long id,
            @Valid @RequestBody FeedSpiritRequest request) {
        return ApiResponse.success(spiritService.feedSpirit(userId, id, request.getEnergyAmount()));
    }

    @PostMapping("/{id}/evolve")
    public ApiResponse<SpiritDTO> evolveSpirit(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long id) {
        return ApiResponse.success(spiritService.evolveSpirit(userId, id));
    }

    @PutMapping("/{id}/activate")
    public ApiResponse<SpiritDTO> activateSpirit(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long id) {
        return ApiResponse.success(spiritService.activateSpirit(userId, id));
    }
}
