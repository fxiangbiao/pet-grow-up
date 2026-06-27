package com.petgrowup.social.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class LeaderboardEntryDTO {
    private int rank;
    private Long userId;
    private String nickname;
    private String avatarUrl;
    private Long value;
    private boolean isCurrentUser;
}
