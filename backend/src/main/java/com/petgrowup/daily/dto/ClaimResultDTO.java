package com.petgrowup.daily.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class ClaimResultDTO {
    private String rewardType;
    private Long energyEarned;
    private String itemName;
    private String itemIcon;
    private Integer consecutiveLoginDays;
    private boolean isMilestone;
    private String milestoneName;
}
