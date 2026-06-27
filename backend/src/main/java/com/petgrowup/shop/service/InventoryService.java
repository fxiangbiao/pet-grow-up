package com.petgrowup.shop.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.shop.dto.ItemDefDTO;
import com.petgrowup.shop.dto.UseItemRequest;
import com.petgrowup.shop.dto.UseItemResultDTO;
import com.petgrowup.shop.dto.UserItemDTO;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import com.petgrowup.spirit.entity.LearningSpirit;
import com.petgrowup.spirit.mapper.SpiritMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class InventoryService {

    private final UserItemMapper userItemMapper;
    private final ItemDefMapper itemDefMapper;
    private final SpiritMapper spiritMapper;

    public InventoryService(UserItemMapper userItemMapper, ItemDefMapper itemDefMapper, SpiritMapper spiritMapper) {
        this.userItemMapper = userItemMapper;
        this.itemDefMapper = itemDefMapper;
        this.spiritMapper = spiritMapper;
    }

    public List<UserItemDTO> getInventory(Long userId) {
        List<UserItem> items = userItemMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));

        if (items.isEmpty()) return List.of();

        List<Long> defIds = items.stream().map(UserItem::getItemDefId).collect(Collectors.toList());
        List<ItemDef> defs = itemDefMapper.selectListByQuery(
                QueryWrapper.create().in("id", defIds));
        Map<Long, ItemDef> defMap = defs.stream().collect(Collectors.toMap(ItemDef::getId, d -> d));

        return items.stream()
                .filter(ui -> ui.getQuantity() > 0)
                .map(ui -> UserItemDTO.builder()
                        .id(ui.getId())
                        .itemDef(toItemDefDTO(defMap.get(ui.getItemDefId())))
                        .quantity(ui.getQuantity())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public UseItemResultDTO useItem(Long userId, UseItemRequest request) {
        Long userItemId = request.getUserItemId();
        Long spiritId = request.getSpiritId();
        int quantity = request.getQuantity() != null ? request.getQuantity() : 1;
        if (quantity <= 0) throw new BusinessException("数量必须大于0");

        UserItem ui = userItemMapper.selectOneById(userItemId);
        if (ui == null || !ui.getUserId().equals(userId)) {
            throw new BusinessException("物品不存在");
        }
        if (ui.getQuantity() < quantity) {
            throw new BusinessException("物品数量不足");
        }

        ItemDef item = itemDefMapper.selectOneById(ui.getItemDefId());
        if (item == null) throw new BusinessException("物品数据异常");

        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null || !spirit.getUserId().equals(userId)) {
            throw new BusinessException("精灵不存在");
        }

        int totalEffect = item.getEffectValue() * quantity;
        int happinessChange = 0;
        int energyChange = 0;
        int affectionChange = 0;

        if ("HAPPINESS".equals(item.getEffectType())) {
            int before = spirit.getHappiness() != null ? spirit.getHappiness() : 0;
            spirit.setHappiness(Math.min(100, before + totalEffect));
            happinessChange = spirit.getHappiness() - before;
        } else if ("ENERGY".equals(item.getEffectType())) {
            int before = spirit.getEnergy() != null ? spirit.getEnergy() : 0;
            spirit.setEnergy(Math.min(100, before + totalEffect));
            energyChange = spirit.getEnergy() - before;
        } else if ("AFFECTION".equals(item.getEffectType())) {
            int before = spirit.getAffection() != null ? spirit.getAffection() : 0;
            spirit.setAffection(before + totalEffect);
            affectionChange = totalEffect;
        }

        spiritMapper.update(spirit);

        int newQty = ui.getQuantity() - quantity;
        ui.setQuantity(newQty);
        userItemMapper.update(ui);

        return UseItemResultDTO.builder()
                .happinessChange(happinessChange)
                .energyChange(energyChange)
                .affectionChange(affectionChange)
                .itemName(item.getName())
                .quantityUsed(quantity)
                .build();
    }

    private ItemDefDTO toItemDefDTO(ItemDef item) {
        if (item == null) return null;
        return ItemDefDTO.builder()
                .id(item.getId())
                .itemKey(item.getItemKey())
                .name(item.getName())
                .description(item.getDescription())
                .category(item.getCategory())
                .effectType(item.getEffectType())
                .effectValue(item.getEffectValue())
                .price(item.getPrice())
                .iconUrl(item.getIconUrl())
                .isConsumable(item.getIsConsumable())
                .displayOrder(item.getDisplayOrder())
                .build();
    }
}
