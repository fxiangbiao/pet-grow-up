package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.UpdateRoleDTO;
import com.petgrowup.admin.dto.UserFilterDTO;
import com.petgrowup.admin.dto.UserPageDTO;
import com.petgrowup.admin.dto.UserPageDTO.UserRowDTO;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminUserService {

    private static final String DEFAULT_PASSWORD = "pet123456";

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    public AdminUserService(UserMapper userMapper, PasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
    }

    public UserPageDTO listUsers(UserFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getRole() != null && !filter.getRole().isBlank()) {
            qw.eq("role", filter.getRole());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String kw = "%" + filter.getKeyword() + "%";
            qw.and(q -> q.like("username", kw).or().like("nickname", kw).or().like("email", kw));
        }

        long total = userMapper.selectCountByQuery(qw);

        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("id", false);

        List<User> users = userMapper.selectListByQuery(qw);

        List<UserRowDTO> rows = users.stream().map(u -> UserRowDTO.builder()
                .id(u.getId())
                .username(u.getUsername())
                .email(u.getEmail())
                .nickname(u.getNickname())
                .avatarUrl(u.getAvatarUrl())
                .role(u.getRole())
                .currentEnergy(u.getCurrentEnergy())
                .totalEnergy(u.getTotalEnergy())
                .consecutiveStudyDays(u.getConsecutiveStudyDays())
                .lastStudyDate(u.getLastStudyDate())
                .lastLoginDate(u.getLastLoginDate())
                .createdAt(u.getCreatedAt())
                .build()).collect(Collectors.toList());

        return UserPageDTO.builder()
                .items(rows).total(total).page(page).size(size).build();
    }

    public User getUser(Long id) {
        User u = userMapper.selectOneById(id);
        if (u == null) throw new BusinessException(404, "用户不存在");
        return u;
    }

    @Transactional
    public User updateRole(Long targetUserId, UpdateRoleDTO dto, Long currentUserId) {
        if (targetUserId.equals(currentUserId)) {
            throw new BusinessException("不能修改自己的角色");
        }

        User u = userMapper.selectOneById(targetUserId);
        if (u == null) throw new BusinessException(404, "用户不存在");

        // Prevent demoting the last admin
        if ("ADMIN".equals(u.getRole()) && "STUDENT".equals(dto.getRole())) {
            long adminCount = userMapper.selectCountByQuery(
                    QueryWrapper.create().eq("role", "ADMIN"));
            if (adminCount <= 1) {
                throw new BusinessException("系统至少需要保留一个管理员，无法降级");
            }
        }

        u.setRole(dto.getRole());
        userMapper.update(u);
        return u;
    }

    @Transactional
    public void resetPassword(Long targetUserId, String newPassword, Long currentUserId) {
        if (targetUserId.equals(currentUserId)) {
            throw new BusinessException("不能重置自己的密码");
        }

        User u = userMapper.selectOneById(targetUserId);
        if (u == null) throw new BusinessException(404, "用户不存在");

        String raw = (newPassword != null && !newPassword.isBlank()) ? newPassword : DEFAULT_PASSWORD;
        u.setPasswordHash(passwordEncoder.encode(raw));
        userMapper.update(u);
    }
}
