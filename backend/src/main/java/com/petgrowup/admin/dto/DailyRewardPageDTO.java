package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyRewardPageDTO {
    private List<DailyRewardRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyRewardRowDTO {
        private Long id;
        private String rewardKey;
        private String name;
        private String description;
        private String rewardType;
        private Long rewardValue;
        private String rewardItemKey;
        private Integer unlockDay;
        private String iconUrl;
        private Integer displayOrder;
        private LocalDateTime createdAt;
    }
}