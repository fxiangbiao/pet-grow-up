package com.petgrowup.auth.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.dto.*;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.common.util.JwtUtil;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
public class AuthService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserMapper userMapper, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userMapper.selectCountByQuery(QueryWrapper.create().eq("username", request.getUsername())) > 0) {
            throw new BusinessException("用户名已存在");
        }
        if (userMapper.selectCountByQuery(QueryWrapper.create().eq("email", request.getEmail())) > 0) {
            throw new BusinessException("邮箱已存在");
        }

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .nickname(request.getUsername())
                .build();

        userMapper.insert(user);

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userMapper.selectOneByQuery(QueryWrapper.create().eq("username", request.getUsername()));

        if (user == null) {
            throw new BadCredentialsException("Invalid username or password");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid username or password");
        }

        updateLoginStreak(user);
        return buildAuthResponse(user);
    }

    private void updateLoginStreak(User user) {
        LocalDate today = LocalDate.now();
        LocalDate lastLogin = user.getLastLoginDate();

        int streak;
        if (lastLogin == null) {
            streak = 1;
        } else if (lastLogin.equals(today)) {
            streak = user.getConsecutiveLoginDays() != null ? user.getConsecutiveLoginDays() : 1;
            user.setConsecutiveLoginDays(streak);
            user.setLastLoginDate(today);
            userMapper.update(user);
            return;
        } else if (lastLogin.equals(today.minusDays(1))) {
            streak = (user.getConsecutiveLoginDays() != null ? user.getConsecutiveLoginDays() : 0) + 1;
        } else {
            streak = 1;
        }

        user.setConsecutiveLoginDays(streak);
        user.setLastLoginDate(today);
        userMapper.update(user);
    }

    public AuthResponse refresh(RefreshTokenRequest request) {
        if (!jwtUtil.validateToken(request.getRefreshToken())) {
            throw new BusinessException("刷新令牌无效或已过期");
        }

        Long userId = jwtUtil.extractUserId(request.getRefreshToken());
        User user = userMapper.selectOneById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getUsername());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        UserDTO userDTO = UserDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .avatarUrl(user.getAvatarUrl())
                .currentEnergy(user.getCurrentEnergy())
                .currentSpiritId(user.getCurrentSpiritId())
                .consecutiveStudyDays(user.getConsecutiveStudyDays())
                .consecutiveLoginDays(user.getConsecutiveLoginDays())
                .dailyRewardClaimed(user.getDailyRewardClaimedDate() != null
                        && user.getDailyRewardClaimedDate().equals(LocalDate.now()))
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(1800000)
                .user(userDTO)
                .build();
    }
}
