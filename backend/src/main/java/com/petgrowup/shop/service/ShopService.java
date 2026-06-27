package com.petgrowup.shop.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.shop.dto.BuyItemRequest;
import com.petgrowup.shop.dto.ItemDefDTO;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ShopService {

    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;
    private final EnergyService energyService;

    public ShopService(ItemDefMapper itemDefMapper, UserItemMapper userItemMapper, EnergyService energyService) {
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
        this.energyService = energyService;
    }

    public List<ItemDefDTO> getItems(String category) {
        QueryWrapper qw = new QueryWrapper().eq("is_purchasable", true).orderBy("display_order", true);
        if (category != null && !category.isBlank()) {
            qw.eq("category", category);
        }
        return itemDefMapper.selectListByQuery(qw).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public void buyItem(Long userId, BuyItemRequest request) {
        Long itemDefId = request.getItemDefId();
        int quantity = request.getQuantity() != null ? request.getQuantity() : 1;
        if (quantity <= 0) throw new BusinessException("数量必须大于0");

        ItemDef item = itemDefMapper.selectOneById(itemDefId);
        if (item == null) throw new BusinessException("物品不存在");
        if (!item.getIsPurchasable()) throw new BusinessException("该物品不可购买");

        long totalPrice = item.getPrice() * quantity;
        energyService.spendEnergy(userId, totalPrice, "shop_purchase");

        UserItem existing = userItemMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("item_def_id", itemDefId));

        if (existing != null) {
            existing.setQuantity(existing.getQuantity() + quantity);
            userItemMapper.update(existing);
        } else {
            UserItem ui = UserItem.builder()
                    .userId(userId)
                    .itemDefId(itemDefId)
                    .quantity(quantity)
                    .build();
            userItemMapper.insert(ui);
        }
    }

    private ItemDefDTO toDTO(ItemDef item) {
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
