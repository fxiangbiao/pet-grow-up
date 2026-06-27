package com.petgrowup.social.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.social.dto.LeaderboardEntryDTO;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class LeaderboardService {

    private final UserMapper userMapper;

    public LeaderboardService(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    public List<LeaderboardEntryDTO> getLeaderboard(String type, int limit, Long currentUserId) {
        if (limit <= 0) limit = 20;

        String orderBy = "streak".equals(type) ? "consecutive_study_days" : "total_energy";

        List<User> users = userMapper.selectListByQuery(
                QueryWrapper.create()
                        .orderBy(orderBy, false)
                        .limit(limit));

        List<LeaderboardEntryDTO> result = new ArrayList<>();
        int rank = 1;
        for (User u : users) {
            long value = "streak".equals(type)
                    ? (u.getConsecutiveStudyDays() != null ? u.getConsecutiveStudyDays() : 0)
                    : (u.getTotalEnergy() != null ? u.getTotalEnergy() : 0);

            result.add(LeaderboardEntryDTO.builder()
                    .rank(rank++)
                    .userId(u.getId())
                    .nickname(u.getNickname())
                    .avatarUrl(u.getAvatarUrl())
                    .value(value)
                    .isCurrentUser(u.getId().equals(currentUserId))
                    .build());
        }
        return result;
    }
}
