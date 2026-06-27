package com.petgrowup.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
@AllArgsConstructor
public class UserProfileDTO {
    private Long id;
    private String username;
    private String nickname;
    private String avatarUrl;
    private Long currentEnergy;
    private Long totalEnergy;
    private Integer consecutiveStudyDays;
    private LocalDate lastStudyDate;
    private Long currentSpiritId;
}
