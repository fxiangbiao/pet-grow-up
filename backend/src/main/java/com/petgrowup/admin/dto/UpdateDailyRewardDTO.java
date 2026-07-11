package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateDailyRewardDTO {
    private String rewardKey;
    private String name;
    private String description;
    private String rewardType;
    private Long rewardValue;
    private String rewardItemKey;
    private Integer unlockDay;
    private String iconUrl;
    private Integer displayOrder;
}