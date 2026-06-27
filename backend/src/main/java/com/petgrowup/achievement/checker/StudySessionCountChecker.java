package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Component;

@Component
public class StudySessionCountChecker extends AbstractAchievementChecker {

    private final StudySessionMapper sessionMapper;

    public StudySessionCountChecker(StudySessionMapper sessionMapper) {
        this.sessionMapper = sessionMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.SESSION_COUNT;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Long count = sessionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COUNT(*)")
                        .eq("user_id", userId)
                        .eq("status", "COMPLETED"),
                Long.class
        );
        return count != null ? count : 0L;
    }
}
