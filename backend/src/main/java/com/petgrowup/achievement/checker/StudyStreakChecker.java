package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.auth.mapper.UserMapper;
import org.springframework.stereotype.Component;

@Component
public class StudyStreakChecker extends AbstractAchievementChecker {

    private final UserMapper userMapper;

    public StudyStreakChecker(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.STREAK_DAYS;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Integer days = userMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("consecutive_study_days")
                        .eq("id", userId),
                Integer.class
        );
        return days != null ? days.longValue() : 0L;
    }
}
