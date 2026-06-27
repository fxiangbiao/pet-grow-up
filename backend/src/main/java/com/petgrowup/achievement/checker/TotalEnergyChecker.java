package com.petgrowup.achievement.checker;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.auth.mapper.UserMapper;
import org.springframework.stereotype.Component;

@Component
public class TotalEnergyChecker extends AbstractAchievementChecker {

    private final UserMapper userMapper;

    public TotalEnergyChecker(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    @Override
    public RequirementType getType() {
        return RequirementType.TOTAL_ENERGY;
    }

    @Override
    public Long getCurrentValue(Long userId, AchievementDef def) {
        Long energy = userMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("total_energy")
                        .eq("id", userId),
                Long.class
        );
        return energy != null ? energy : 0L;
    }
}
