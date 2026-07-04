package com.petgrowup.daily.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.daily.dto.ClaimResultDTO;
import com.petgrowup.daily.dto.DailyRewardDTO;
import com.petgrowup.daily.dto.DailyRewardStatusDTO;
import com.petgrowup.daily.entity.DailyRewardDef;
import com.petgrowup.daily.mapper.DailyRewardDefMapper;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DailyRewardService {

    private static final String[] FOOD_KEYS = {"energy_candy", "happy_cake", "mixed_treat", "energy_candy_plus"};

    private final DailyRewardDefMapper rewardDefMapper;
    private final UserMapper userMapper;
    private final EnergyService energyService;
    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;

    public DailyRewardService(DailyRewardDefMapper rewardDefMapper, UserMapper userMapper,
                              EnergyService energyService, ItemDefMapper itemDefMapper,
                              UserItemMapper userItemMapper) {
        this.rewardDefMapper = rewardDefMapper;
        this.userMapper = userMapper;
        this.energyService = energyService;
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
    }

    public DailyRewardStatusDTO getStatus(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        LocalDate today = LocalDate.now();
        boolean claimedToday = user.getDailyRewardClaimedDate() != null
                && user.getDailyRewardClaimedDate().equals(today);

        int streak = user.getConsecutiveLoginDays() != null ? user.getConsecutiveLoginDays() : 0;

        List<DailyRewardDef> allDefs = rewardDefMapper.selectAll();

        // Today's reward: milestone if today matches, else random daily
        DailyRewardDTO todayReward = null;
        boolean eligible = !claimedToday;

        if (eligible) {
            boolean isMilestoneDay = allDefs.stream().anyMatch(d -> d.getUnlockDay() > 1 && d.getUnlockDay() == streak);
            if (isMilestoneDay) {
                DailyRewardDef milestone = allDefs.stream()
                        .filter(d -> d.getUnlockDay() == streak && d.getUnlockDay() > 1)
                        .findFirst().orElse(null);
                if (milestone != null) todayReward = toDTO(milestone, streak, false);
            } else {
                // Random daily reward (unlock_day=1)
                List<DailyRewardDef> dailies = allDefs.stream()
                        .filter(d -> d.getUnlockDay() == 1).toList();
                if (!dailies.isEmpty()) {
                    DailyRewardDef picked = dailies.get(new Random().nextInt(dailies.size()));
                    todayReward = toDTO(picked, 1, false);
                }
            }
        }

        // Upcoming milestones
        List<DailyRewardDTO> milestones = allDefs.stream()
                .filter(d -> d.getUnlockDay() > 1 && d.getUnlockDay() > streak)
                .sorted(Comparator.comparingInt(DailyRewardDef::getUnlockDay))
                .limit(3)
                .map(d -> toDTO(d, d.getUnlockDay(), false))
                .collect(Collectors.toList());

        return DailyRewardStatusDTO.builder()
                .eligible(eligible)
                .claimedToday(claimedToday)
                .consecutiveLoginDays(streak)
                .todayReward(todayReward)
                .recentRewards(Collections.emptyList())
                .upcomingMilestones(milestones)
                .build();
    }

    @Transactional
    public ClaimResultDTO claim(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        LocalDate today = LocalDate.now();
        if (user.getDailyRewardClaimedDate() != null && user.getDailyRewardClaimedDate().equals(today)) {
            throw new BusinessException("今日已领取过盲盒奖励");
        }

        int streak = user.getConsecutiveLoginDays() != null ? user.getConsecutiveLoginDays() : 0;
        List<DailyRewardDef> allDefs = rewardDefMapper.selectAll();

        // Determine which reward to give
        DailyRewardDef reward;
        boolean isMilestone = false;
        boolean isMilestoneDay = allDefs.stream().anyMatch(d -> d.getUnlockDay() > 1 && d.getUnlockDay() == streak);

        if (isMilestoneDay) {
            reward = allDefs.stream()
                    .filter(d -> d.getUnlockDay() == streak && d.getUnlockDay() > 1)
                    .findFirst().orElse(null);
            isMilestone = true;
        } else {
            // Random daily
            List<DailyRewardDef> dailies = allDefs.stream()
                    .filter(d -> d.getUnlockDay() == 1).toList();
            reward = dailies.isEmpty() ? null : dailies.get(new Random().nextInt(dailies.size()));
        }

        if (reward == null) throw new BusinessException("没有可领取的奖励");

        // Award the reward
        Long energyEarned = 0L;
        String itemName = null;
        String itemIcon = null;

        if ("ENERGY".equals(reward.getRewardType())) {
            Long amount = reward.getRewardValue() != null ? reward.getRewardValue() : 0L;
            energyService.earnEnergy(userId, amount, "daily_reward", "daily_reward_def", reward.getId());
            energyEarned = amount;
        } else if ("ITEM".equals(reward.getRewardType())) {
            String itemKey = reward.getRewardItemKey();
            if ("RANDOM_FOOD".equals(itemKey)) {
                itemKey = FOOD_KEYS[new Random().nextInt(FOOD_KEYS.length)];
            }
            ItemDef item = itemDefMapper.selectOneByQuery(
                    QueryWrapper.create().eq("item_key", itemKey));
            if (item != null) {
                grantItem(userId, item);
                itemName = item.getName();
                itemIcon = item.getIconUrl();
            }
        } else if ("ACCESSORY".equals(reward.getRewardType())) {
            ItemDef item = itemDefMapper.selectOneByQuery(
                    QueryWrapper.create().eq("item_key", reward.getRewardItemKey()));
            if (item != null) {
                grantItem(userId, item);
                itemName = item.getName();
                itemIcon = item.getIconUrl();
            }
        }

        // Mark claimed
        user.setDailyRewardClaimedDate(today);
        userMapper.update(user);

        return ClaimResultDTO.builder()
                .rewardType(reward.getRewardType())
                .energyEarned(energyEarned)
                .itemName(itemName)
                .itemIcon(itemIcon)
                .consecutiveLoginDays(streak)
                .isMilestone(isMilestone)
                .milestoneName(isMilestone ? reward.getName() : null)
                .build();
    }

    private void grantItem(Long userId, ItemDef item) {
        UserItem existing = userItemMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("item_def_id", item.getId()));
        if (existing != null) {
            existing.setQuantity(existing.getQuantity() + 1);
            userItemMapper.update(existing);
        } else {
            userItemMapper.insert(UserItem.builder()
                    .userId(userId).itemDefId(item.getId()).quantity(1).build());
        }
    }

    private DailyRewardDTO toDTO(DailyRewardDef def, int streak, boolean claimed) {
        return DailyRewardDTO.builder()
                .id(def.getId())
                .rewardKey(def.getRewardKey())
                .name(def.getName())
                .description(def.getDescription())
                .rewardType(def.getRewardType())
                .rewardValue(def.getRewardValue())
                .rewardItemKey(def.getRewardItemKey())
                .iconUrl(def.getIconUrl())
                .unlockDay(def.getUnlockDay())
                .isMilestone(def.getUnlockDay() > 1)
                .claimed(claimed)
                .build();
    }
}
