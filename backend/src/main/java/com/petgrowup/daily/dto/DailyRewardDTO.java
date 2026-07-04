package com.petgrowup.daily.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class DailyRewardDTO {
    private Long id;
    private String rewardKey;
    private String name;
    private String description;
    private String rewardType;
    private Long rewardValue;
    private String rewardItemKey;
    private String rewardItemName;
    private String iconUrl;
    private int unlockDay;
    private boolean isMilestone;
    private boolean claimed;
}
