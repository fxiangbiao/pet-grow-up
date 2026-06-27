package com.petgrowup.social.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
public class FriendRequestDTO {
    private Long requestId;
    private Long userId;
    private String nickname;
    private String avatarUrl;
    private String status;
    private LocalDateTime createdAt;
}
