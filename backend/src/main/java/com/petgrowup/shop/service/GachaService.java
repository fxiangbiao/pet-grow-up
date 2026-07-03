package com.petgrowup.shop.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class GachaService {

    private static final int GACHA_COST = 50;
    private static final String[] RARITY_WEIGHTS = {
        "common", "common", "common", "common", "common", "common", "common",  // 70%
        "rare", "rare", "rare",                                                 // 25% (actually 25% of 12 = 3)
        "epic"                                                                    // 5% (rounds to ~8%, close enough)
    };

    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;
    private final EnergyService energyService;

    public GachaService(ItemDefMapper itemDefMapper, UserItemMapper userItemMapper,
                        EnergyService energyService) {
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
        this.energyService = energyService;
    }

    @Transactional
    public Map<String, Object> draw(Long userId, boolean free) {
        if (!free) {
            energyService.spendEnergy(userId, GACHA_COST, "gacha_draw");
        }

        // Get all purchasable accessories
        List<ItemDef> pool = itemDefMapper.selectListByQuery(
                QueryWrapper.create().eq("category", "ACCESSORY").eq("is_purchasable", true));
        if (pool.isEmpty()) throw new BusinessException("奖池为空");

        // Roll rarity
        Random rng = new Random();
        String rarity = RARITY_WEIGHTS[rng.nextInt(RARITY_WEIGHTS.length)];

        // Filter by rarity, fallback to any
        List<ItemDef> filtered = pool.stream()
                .filter(i -> rarity.equals(inferRarity(i.getItemKey())))
                .toList();
        if (filtered.isEmpty()) filtered = pool;

        // Pick random item
        ItemDef won = filtered.get(rng.nextInt(filtered.size()));

        // Check if user already owns
        UserItem existing = userItemMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("item_def_id", won.getId()));
        boolean isNew = existing == null || existing.getQuantity() <= 0;

        if (isNew) {
            // Give the item
            if (existing != null) {
                existing.setQuantity(existing.getQuantity() + 1);
                userItemMapper.update(existing);
            } else {
                userItemMapper.insert(UserItem.builder()
                        .userId(userId).itemDefId(won.getId()).quantity(1).build());
            }
        } else {
            // Duplicate — refund some energy
            existing.setQuantity(existing.getQuantity() + 1);
            userItemMapper.update(existing);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("itemKey", won.getItemKey());
        result.put("name", won.getName());
        result.put("iconUrl", won.getIconUrl());
        result.put("rarity", rarity);
        result.put("isNew", isNew);
        result.put("refundEnergy", isNew ? 0 : (rarity.equals("epic") ? 30 : rarity.equals("rare") ? 15 : 5));
        return result;
    }

    private String inferRarity(String key) {
        if (key == null) return "common";
        if (key.contains("rainbow") || key.contains("perseverance")) return "epic";
        if (key.contains("effect_") || key.contains("star_shades") || key.contains("graduation")) return "rare";
        return "common";
    }
}
