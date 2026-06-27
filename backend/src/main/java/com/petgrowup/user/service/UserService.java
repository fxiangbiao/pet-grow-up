package com.petgrowup.user.service;

import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.ResourceNotFoundException;
import com.petgrowup.user.dto.UserProfileDTO;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserMapper userMapper;

    public UserService(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    public UserProfileDTO getProfile(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new ResourceNotFoundException("User", userId);

        return UserProfileDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .avatarUrl(user.getAvatarUrl())
                .currentEnergy(user.getCurrentEnergy())
                .totalEnergy(user.getTotalEnergy())
                .consecutiveStudyDays(user.getConsecutiveStudyDays())
                .lastStudyDate(user.getLastStudyDate())
                .currentSpiritId(user.getCurrentSpiritId())
                .build();
    }
}
