package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Component;

@Component
public class AllSubjectsChecker extends AbstractAchievementChecker {

    private final StudySessionMapper sessionMapper;

    public AllSubjectsChecker(StudySessionMapper sessionMapper) {
        this.sessionMapper = sessionMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.ALL_SUBJECTS_TRIED;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Long count = sessionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COUNT(DISTINCT subject)")
                        .eq("user_id", userId),
                Long.class
        );
        return count != null ? count : 0L;
    }
}
