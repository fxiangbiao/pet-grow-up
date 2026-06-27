package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.spirit.mapper.SpiritMapper;
import org.springframework.stereotype.Component;

@Component
public class SpiritEvolutionChecker extends AbstractAchievementChecker {

    private final SpiritMapper spiritMapper;

    public SpiritEvolutionChecker(SpiritMapper spiritMapper) {
        this.spiritMapper = spiritMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.FIRST_EVOLUTION;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Long count = spiritMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COUNT(*)")
                        .eq("user_id", userId)
                        .gt("current_evolution_stage", 1),
                Long.class
        );
        return count != null ? count : 0L;
    }
}
