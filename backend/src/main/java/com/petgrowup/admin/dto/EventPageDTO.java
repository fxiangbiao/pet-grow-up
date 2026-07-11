package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventPageDTO {
    private List<EventRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EventRowDTO {
        private Long id;
        private String eventKey;
        private String name;
        private String description;
        private String eventType;
        private BigDecimal triggerChance;
        private BigDecimal minAccuracy;
        private Integer minStreak;
        private Long rewardEnergy;
        private String rewardItemKey;
        private Integer rewardAffection;
        private String displayText;
        private String iconUrl;
        private LocalDateTime createdAt;
    }
}