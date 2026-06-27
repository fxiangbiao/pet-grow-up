package com.petgrowup.social.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.social.dto.*;
import com.petgrowup.social.entity.FriendRequest;
import com.petgrowup.social.entity.UserFriend;
import com.petgrowup.social.mapper.FriendRequestMapper;
import com.petgrowup.social.mapper.UserFriendMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class FriendService {

    private final FriendRequestMapper friendRequestMapper;
    private final UserFriendMapper userFriendMapper;
    private final UserMapper userMapper;

    public FriendService(FriendRequestMapper friendRequestMapper,
                         UserFriendMapper userFriendMapper,
                         UserMapper userMapper) {
        this.friendRequestMapper = friendRequestMapper;
        this.userFriendMapper = userFriendMapper;
        this.userMapper = userMapper;
    }

    @Transactional
    public void sendRequest(Long senderId, Long receiverId) {
        if (senderId.equals(receiverId)) {
            throw new BusinessException("不能添加自己为好友");
        }

        long friendCount = userFriendMapper.selectCountByQuery(
                QueryWrapper.create().eq("user_id", senderId).eq("friend_id", receiverId));
        if (friendCount > 0) {
            throw new BusinessException("已经是好友了");
        }

        long pendingSent = friendRequestMapper.selectCountByQuery(
                QueryWrapper.create().eq("sender_id", senderId).eq("receiver_id", receiverId).eq("status", "PENDING"));
        long pendingReceived = friendRequestMapper.selectCountByQuery(
                QueryWrapper.create().eq("sender_id", receiverId).eq("receiver_id", senderId).eq("status", "PENDING"));
        if (pendingSent > 0 || pendingReceived > 0) {
            throw new BusinessException("已经发送过好友请求了");
        }

        FriendRequest request = FriendRequest.builder()
                .senderId(senderId)
                .receiverId(receiverId)
                .status("PENDING")
                .build();
        friendRequestMapper.insert(request);
    }

    @Transactional
    public void acceptRequest(Long userId, Long requestId) {
        FriendRequest req = friendRequestMapper.selectOneById(requestId);
        if (req == null || !req.getReceiverId().equals(userId)) {
            throw new BusinessException("好友请求不存在");
        }
        if (!"PENDING".equals(req.getStatus())) {
            throw new BusinessException("好友请求已处理");
        }

        UserFriend uf1 = UserFriend.builder().userId(userId).friendId(req.getSenderId()).build();
        UserFriend uf2 = UserFriend.builder().userId(req.getSenderId()).friendId(userId).build();
        userFriendMapper.insert(uf1);
        userFriendMapper.insert(uf2);

        req.setStatus("ACCEPTED");
        friendRequestMapper.update(req);
    }

    @Transactional
    public void rejectRequest(Long userId, Long requestId) {
        FriendRequest req = friendRequestMapper.selectOneById(requestId);
        if (req == null || !req.getReceiverId().equals(userId)) {
            throw new BusinessException("好友请求不存在");
        }
        if (!"PENDING".equals(req.getStatus())) {
            throw new BusinessException("好友请求已处理");
        }
        req.setStatus("REJECTED");
        friendRequestMapper.update(req);
    }

    @Transactional
    public void removeFriend(Long userId, Long friendId) {
        int deleted1 = userFriendMapper.deleteByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("friend_id", friendId));
        int deleted2 = userFriendMapper.deleteByQuery(
                QueryWrapper.create().eq("user_id", friendId).eq("friend_id", userId));
        if (deleted1 == 0 && deleted2 == 0) {
            throw new BusinessException("好友不存在");
        }
    }

    public List<FriendDTO> getFriends(Long userId) {
        List<UserFriend> ufs = userFriendMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (ufs.isEmpty()) return List.of();

        List<Long> friendIds = ufs.stream().map(UserFriend::getFriendId).collect(Collectors.toList());
        List<User> friends = userMapper.selectListByQuery(
                QueryWrapper.create().in("id", friendIds));

        Map<Long, UserFriend> ufMap = ufs.stream()
                .collect(Collectors.toMap(UserFriend::getFriendId, uf -> uf));

        return friends.stream().map(u -> FriendDTO.builder()
                .friendId(u.getId())
                .nickname(u.getNickname())
                .avatarUrl(u.getAvatarUrl())
                .totalEnergy(u.getTotalEnergy())
                .consecutiveStudyDays(u.getConsecutiveStudyDays())
                .becameFriendsAt(ufMap.get(u.getId()) != null ? ufMap.get(u.getId()).getCreatedAt() : null)
                .build()).collect(Collectors.toList());
    }

    public List<FriendRequestDTO> getIncomingRequests(Long userId) {
        List<FriendRequest> requests = friendRequestMapper.selectListByQuery(
                QueryWrapper.create().eq("receiver_id", userId).eq("status", "PENDING")
                        .orderBy("created_at", false));
        return toFriendRequestDTOs(requests, true);
    }

    public List<FriendRequestDTO> getSentRequests(Long userId) {
        List<FriendRequest> requests = friendRequestMapper.selectListByQuery(
                QueryWrapper.create().eq("sender_id", userId).eq("status", "PENDING")
                        .orderBy("created_at", false));
        return toFriendRequestDTOs(requests, false);
    }

    public List<UserSearchResultDTO> searchUsers(Long userId, String query) {
        if (query == null || query.trim().isEmpty()) return List.of();
        String pattern = "%" + query.trim() + "%";

        // Search by username or nickname
        List<User> usernameMatches = userMapper.selectListByQuery(
                QueryWrapper.create().like("username", pattern).limit(20));
        List<User> nicknameMatches = userMapper.selectListByQuery(
                QueryWrapper.create().like("nickname", pattern).limit(20));

        // Merge and deduplicate
        java.util.LinkedHashMap<Long, User> merged = new java.util.LinkedHashMap<>();
        for (User u : usernameMatches) merged.put(u.getId(), u);
        for (User u : nicknameMatches) merged.put(u.getId(), u);

        List<UserSearchResultDTO> results = new ArrayList<>();
        for (User u : merged.values()) {
            if (u.getId().equals(userId)) continue;

            boolean isFriend = userFriendMapper.selectCountByQuery(
                    QueryWrapper.create().eq("user_id", userId).eq("friend_id", u.getId())) > 0;

            boolean hasPending = friendRequestMapper.selectCountByQuery(
                    QueryWrapper.create().eq("sender_id", userId).eq("receiver_id", u.getId()).eq("status", "PENDING")) > 0
                    || friendRequestMapper.selectCountByQuery(
                    QueryWrapper.create().eq("sender_id", u.getId()).eq("receiver_id", userId).eq("status", "PENDING")) > 0;

            results.add(UserSearchResultDTO.builder()
                    .userId(u.getId())
                    .nickname(u.getNickname())
                    .avatarUrl(u.getAvatarUrl())
                    .isFriend(isFriend)
                    .hasPendingRequest(hasPending)
                    .isSelf(false)
                    .build());
        }
        return results;
    }

    private List<FriendRequestDTO> toFriendRequestDTOs(List<FriendRequest> requests, boolean isIncoming) {
        if (requests.isEmpty()) return List.of();
        List<Long> userIds = requests.stream()
                .map(r -> isIncoming ? r.getSenderId() : r.getReceiverId())
                .collect(Collectors.toList());
        List<User> users = userMapper.selectListByQuery(
                QueryWrapper.create().in("id", userIds));
        Map<Long, User> userMap = users.stream().collect(Collectors.toMap(User::getId, u -> u));

        return requests.stream().map(r -> {
            Long otherId = isIncoming ? r.getSenderId() : r.getReceiverId();
            User u = userMap.get(otherId);
            return FriendRequestDTO.builder()
                    .requestId(r.getId())
                    .userId(otherId)
                    .nickname(u != null ? u.getNickname() : "未知用户")
                    .avatarUrl(u != null ? u.getAvatarUrl() : null)
                    .status(r.getStatus())
                    .createdAt(r.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());
    }
}
