package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.spirit.mapper.SpiritMapper;
import org.springframework.stereotype.Component;

@Component
public class MaxAffectionChecker extends AbstractAchievementChecker {

    private final SpiritMapper spiritMapper;

    public MaxAffectionChecker(SpiritMapper spiritMapper) {
        this.spiritMapper = spiritMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.MAX_AFFECTION;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Integer max = spiritMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(MAX(affection), 0)")
                        .eq("user_id", userId),
                Integer.class
        );
        return max != null ? max.longValue() : 0L;
    }
}
