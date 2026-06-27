package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Component;

@Component
public class SubjectMilestoneChecker extends AbstractAchievementChecker {

    private final StudySessionMapper sessionMapper;

    public SubjectMilestoneChecker(StudySessionMapper sessionMapper) {
        this.sessionMapper = sessionMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.SUBJECT_MILESTONE;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        if (def.getSubject() == null) return 0L;
        Long count = sessionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COUNT(*)")
                        .eq("user_id", userId)
                        .eq("status", "COMPLETED")
                        .eq("subject", def.getSubject()),
                Long.class
        );
        return count != null ? count : 0L;
    }
}
