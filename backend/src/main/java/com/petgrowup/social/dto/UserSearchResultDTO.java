package com.petgrowup.social.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class UserSearchResultDTO {
    private Long userId;
    private String nickname;
    private String avatarUrl;
    private boolean isFriend;
    private boolean hasPendingRequest;
    private boolean isSelf;
}
