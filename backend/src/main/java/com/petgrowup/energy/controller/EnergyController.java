package com.petgrowup.energy.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.energy.dto.EnergyBalanceDTO;
import com.petgrowup.energy.dto.EnergyTransactionDTO;
import com.petgrowup.energy.service.EnergyService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/energy")
public class EnergyController {

    private final EnergyService energyService;

    public EnergyController(EnergyService energyService) {
        this.energyService = energyService;
    }

    @GetMapping("/balance")
    public ApiResponse<EnergyBalanceDTO> getBalance(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(energyService.getBalance(userId));
    }

    @GetMapping("/transactions")
    public ApiResponse<List<EnergyTransactionDTO>> getTransactions(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.success(energyService.getTransactions(userId, page, size));
    }
}
