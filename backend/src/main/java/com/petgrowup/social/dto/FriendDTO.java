package com.petgrowup.social.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
public class FriendDTO {
    private Long friendId;
    private String nickname;
    private String avatarUrl;
    private Long totalEnergy;
    private Integer consecutiveStudyDays;
    private LocalDateTime becameFriendsAt;
}
