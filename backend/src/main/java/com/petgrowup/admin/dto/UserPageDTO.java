package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPageDTO {
    private List<UserRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserRowDTO {
        private Long id;
        private String username;
        private String email;
        private String nickname;
        private String avatarUrl;
        private String role;
        private Long currentEnergy;
        private Long totalEnergy;
        private Integer consecutiveStudyDays;
        private LocalDate lastStudyDate;
        private LocalDate lastLoginDate;
        private LocalDateTime createdAt;
    }
}
