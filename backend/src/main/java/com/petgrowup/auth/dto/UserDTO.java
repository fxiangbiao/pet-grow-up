package com.petgrowup.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    private Long id;
    private String username;
    private String nickname;
    private String avatarUrl;
    private Long currentEnergy;
    private Long currentSpiritId;
    private Integer consecutiveStudyDays;
    private Integer consecutiveLoginDays;
    private Boolean dailyRewardClaimed;
    private String role;
}
