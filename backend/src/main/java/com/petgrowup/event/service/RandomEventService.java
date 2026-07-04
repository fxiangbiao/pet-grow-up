package com.petgrowup.event.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.event.dto.RandomEventDTO;
import com.petgrowup.event.entity.RandomEventDef;
import com.petgrowup.event.mapper.RandomEventDefMapper;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import com.petgrowup.spirit.service.SpiritService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Random;

@Service
public class RandomEventService {

    private final RandomEventDefMapper eventDefMapper;
    private final EnergyService energyService;
    private final SpiritService spiritService;
    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;
    private final Random rng = new Random();

    public RandomEventService(RandomEventDefMapper eventDefMapper, EnergyService energyService,
                              SpiritService spiritService, ItemDefMapper itemDefMapper,
                              UserItemMapper userItemMapper) {
        this.eventDefMapper = eventDefMapper;
        this.energyService = energyService;
        this.spiritService = spiritService;
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
    }

    public RandomEventDTO checkAndTrigger(Long userId, int streak, double accuracy,
                                           Long spiritId, Long sessionId) {
        List<RandomEventDef> allEvents = eventDefMapper.selectAll();
        if (allEvents.isEmpty()) return null;

        // Filter eligible events
        List<RandomEventDef> eligible = allEvents.stream()
                .filter(e -> e.getMinAccuracy().doubleValue() <= accuracy)
                .filter(e -> e.getMinStreak() <= streak)
                .toList();

        if (eligible.isEmpty()) return null;

        // Roll independently for each event, return first hit
        for (RandomEventDef def : eligible) {
            if (rng.nextDouble() < def.getTriggerChance().doubleValue()) {
                return applyEvent(userId, def, spiritId, sessionId);
            }
        }

        return null;
    }

    public RandomEventDTO replayFromKey(String eventKey, Long sessionId) {
        if (eventKey == null) return null;
        RandomEventDef def = eventDefMapper.selectOneByQuery(
                QueryWrapper.create().eq("event_key", eventKey));
        if (def == null) return null;
        return fromDef(def);
    }

    private RandomEventDTO applyEvent(Long userId, RandomEventDef def, Long spiritId, Long sessionId) {
        Long bonusEnergy = 0L;
        String rewardItemName = null;
        int affectionGained = 0;
        boolean isDoubleReward = false;

        switch (def.getEventType()) {
            case "BONUS_ENERGY":
                bonusEnergy = def.getRewardEnergy();
                energyService.earnEnergy(userId, bonusEnergy, "random_event", "random_event_def", def.getId());
                break;
            case "SPIRIT_GIFT":
                affectionGained = def.getRewardAffection();
                if (spiritId != null && affectionGained > 0) {
                    spiritService.updateAffection(spiritId, affectionGained);
                }
                if (def.getRewardItemKey() != null) {
                    ItemDef item = itemDefMapper.selectOneByQuery(
                            QueryWrapper.create().eq("item_key", def.getRewardItemKey()));
                    if (item != null) {
                        grantItem(userId, item);
                        rewardItemName = item.getName();
                    }
                }
                break;
            case "DOUBLE_REWARD":
                // Double the session energy — handled in ExplorationService
                isDoubleReward = true;
                bonusEnergy = def.getRewardEnergy();
                break;
            case "STREAK_BONUS":
                bonusEnergy = def.getRewardEnergy();
                affectionGained = def.getRewardAffection();
                energyService.earnEnergy(userId, bonusEnergy, "random_event", "random_event_def", def.getId());
                if (spiritId != null && affectionGained > 0) {
                    spiritService.updateAffection(spiritId, affectionGained);
                }
                break;
            case "FREE_ITEM":
                affectionGained = def.getRewardAffection();
                if (spiritId != null && affectionGained > 0) {
                    spiritService.updateAffection(spiritId, affectionGained);
                }
                break;
        }

        RandomEventDTO dto = fromDef(def);
        dto.setBonusEnergy(bonusEnergy);
        dto.setRewardItemName(rewardItemName);
        dto.setAffectionGained(affectionGained);
        dto.setDoubleReward(isDoubleReward);
        return dto;
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

    private RandomEventDTO fromDef(RandomEventDef def) {
        return RandomEventDTO.builder()
                .eventKey(def.getEventKey())
                .name(def.getName())
                .description(def.getDescription())
                .eventType(def.getEventType())
                .iconUrl(def.getIconUrl())
                .displayText(def.getDisplayText())
                .bonusEnergy(0L)
                .rewardItemName(null)
                .affectionGained(0)
                .isDoubleReward(false)
                .build();
    }
}
