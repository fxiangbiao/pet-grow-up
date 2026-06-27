package com.petgrowup.energy.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("energy_transaction")
public class EnergyTransaction {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("user_id")
    private Long userId;

    private Long amount;

    @Column("transaction_type")
    private String transactionType;

    private String source;

    @Column("reference_type")
    private String referenceType;

    @Column("reference_id")
    private Long referenceId;

    @Column("balance_after")
    private Long balanceAfter;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
