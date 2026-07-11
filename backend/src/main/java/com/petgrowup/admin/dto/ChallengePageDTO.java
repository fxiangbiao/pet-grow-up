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
public class ChallengePageDTO {
    private List<ChallengeRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChallengeRowDTO {
        private Long id;
        private String challengeType;
        private String description;
        private Integer targetValue;
        private Long rewardEnergy;
        private String iconUrl;
        private Integer displayOrder;
        private LocalDateTime createdAt;
    }
}