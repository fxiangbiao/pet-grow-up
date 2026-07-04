package com.petgrowup.daily.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class DailyRewardStatusDTO {
    private boolean eligible;
    private boolean claimedToday;
    private Integer consecutiveLoginDays;
    private DailyRewardDTO todayReward;
    private List<DailyRewardDTO> recentRewards;
    private List<DailyRewardDTO> upcomingMilestones;
}
