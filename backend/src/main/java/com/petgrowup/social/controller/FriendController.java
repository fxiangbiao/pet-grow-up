package com.petgrowup.social.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.social.dto.*;
import com.petgrowup.social.service.FriendService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/social/friends")
public class FriendController {

    private final FriendService friendService;

    public FriendController(FriendService friendService) {
        this.friendService = friendService;
    }

    @GetMapping
    public ApiResponse<List<FriendDTO>> getFriends(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(friendService.getFriends(userId));
    }

    @GetMapping("/requests")
    public ApiResponse<List<FriendRequestDTO>> getIncomingRequests(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(friendService.getIncomingRequests(userId));
    }

    @GetMapping("/requests/sent")
    public ApiResponse<List<FriendRequestDTO>> getSentRequests(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(friendService.getSentRequests(userId));
    }

    @PostMapping("/requests")
    public ApiResponse<Void> sendRequest(@AuthenticationPrincipal Long userId,
                                          @RequestBody SendFriendRequestDTO dto) {
        friendService.sendRequest(userId, dto.getReceiverId());
        return ApiResponse.success(null);
    }

    @PostMapping("/requests/{requestId}/accept")
    public ApiResponse<Void> acceptRequest(@AuthenticationPrincipal Long userId,
                                            @PathVariable Long requestId) {
        friendService.acceptRequest(userId, requestId);
        return ApiResponse.success(null);
    }

    @PostMapping("/requests/{requestId}/reject")
    public ApiResponse<Void> rejectRequest(@AuthenticationPrincipal Long userId,
                                            @PathVariable Long requestId) {
        friendService.rejectRequest(userId, requestId);
        return ApiResponse.success(null);
    }

    @DeleteMapping("/{friendId}")
    public ApiResponse<Void> removeFriend(@AuthenticationPrincipal Long userId,
                                           @PathVariable Long friendId) {
        friendService.removeFriend(userId, friendId);
        return ApiResponse.success(null);
    }

    @GetMapping("/search")
    public ApiResponse<List<UserSearchResultDTO>> searchUsers(@AuthenticationPrincipal Long userId,
                                                               @RequestParam String q) {
        return ApiResponse.success(friendService.searchUsers(userId, q));
    }
}
