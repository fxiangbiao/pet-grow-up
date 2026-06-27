package com.petgrowup.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
public class EnergyTransactionDTO {
    private Long id;
    private Long amount;
    private String transactionType;
    private String source;
    private Long balanceAfter;
    private LocalDateTime createdAt;
}
