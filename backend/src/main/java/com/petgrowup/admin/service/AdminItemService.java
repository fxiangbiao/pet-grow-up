package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.CreateItemDefDTO;
import com.petgrowup.admin.dto.ItemFilterDTO;
import com.petgrowup.admin.dto.ItemPageDTO;
import com.petgrowup.admin.dto.ItemPageDTO.ItemRowDTO;
import com.petgrowup.admin.dto.UpdateItemDefDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminItemService {

    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;

    public AdminItemService(ItemDefMapper itemDefMapper, UserItemMapper userItemMapper) {
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
    }

    public ItemPageDTO listItems(ItemFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getCategory() != null && !filter.getCategory().isBlank()) {
            qw.eq("category", filter.getCategory());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String kw = "%" + filter.getKeyword() + "%";
            qw.and(q -> q.like("name", kw).or().like("item_key", kw));
        }

        long total = itemDefMapper.selectCountByQuery(qw);

        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("display_order", true);

        List<ItemDef> items = itemDefMapper.selectListByQuery(qw);

        List<ItemRowDTO> rows = items.stream().map(i -> ItemRowDTO.builder()
                .id(i.getId())
                .itemKey(i.getItemKey())
                .name(i.getName())
                .description(i.getDescription())
                .category(i.getCategory())
                .effectType(i.getEffectType())
                .effectValue(i.getEffectValue())
                .price(i.getPrice())
                .iconUrl(i.getIconUrl())
                .isConsumable(i.getIsConsumable())
                .isPurchasable(i.getIsPurchasable())
                .displayOrder(i.getDisplayOrder())
                .createdAt(i.getCreatedAt())
                .build()).collect(Collectors.toList());

        return ItemPageDTO.builder()
                .items(rows).total(total).page(page).size(size).build();
    }

    public ItemDef getItem(Long id) {
        ItemDef i = itemDefMapper.selectOneById(id);
        if (i == null) throw new BusinessException(404, "商品不存在");
        return i;
    }

    @Transactional
    public ItemDef createItem(CreateItemDefDTO dto) {
        // Check item_key uniqueness
        long existing = itemDefMapper.selectCountByQuery(
                QueryWrapper.create().eq("item_key", dto.getItemKey()));
        if (existing > 0) {
            throw new BusinessException("商品标识 " + dto.getItemKey() + " 已存在");
        }

        ItemDef item = ItemDef.builder()
                .itemKey(dto.getItemKey())
                .name(dto.getName())
                .description(dto.getDescription())
                .category(dto.getCategory())
                .effectType(dto.getEffectType())
                .effectValue(dto.getEffectValue() != null ? dto.getEffectValue() : 0)
                .price(dto.getPrice() != null ? dto.getPrice() : 0L)
                .iconUrl(dto.getIconUrl())
                .isConsumable(dto.getIsConsumable() != null ? dto.getIsConsumable() : true)
                .isPurchasable(dto.getIsPurchasable() != null ? dto.getIsPurchasable() : true)
                .displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .build();
        itemDefMapper.insert(item);
        return item;
    }

    @Transactional
    public ItemDef updateItem(Long id, UpdateItemDefDTO dto) {
        ItemDef i = itemDefMapper.selectOneById(id);
        if (i == null) throw new BusinessException(404, "商品不存在");

        if (dto.getItemKey() != null) {
            if (!dto.getItemKey().equals(i.getItemKey())) {
                long existing = itemDefMapper.selectCountByQuery(
                        QueryWrapper.create().eq("item_key", dto.getItemKey()));
                if (existing > 0) {
                    throw new BusinessException("商品标识 " + dto.getItemKey() + " 已存在");
                }
            }
            i.setItemKey(dto.getItemKey());
        }
        if (dto.getName() != null) i.setName(dto.getName());
        if (dto.getDescription() != null) i.setDescription(dto.getDescription());
        if (dto.getCategory() != null) i.setCategory(dto.getCategory());
        if (dto.getEffectType() != null) i.setEffectType(dto.getEffectType());
        if (dto.getEffectValue() != null) i.setEffectValue(dto.getEffectValue());
        if (dto.getPrice() != null) i.setPrice(dto.getPrice());
        if (dto.getIconUrl() != null) i.setIconUrl(dto.getIconUrl());
        if (dto.getIsConsumable() != null) i.setIsConsumable(dto.getIsConsumable());
        if (dto.getIsPurchasable() != null) i.setIsPurchasable(dto.getIsPurchasable());
        if (dto.getDisplayOrder() != null) i.setDisplayOrder(dto.getDisplayOrder());

        itemDefMapper.update(i);
        return i;
    }

    @Transactional
    public void deleteItem(Long id) {
        ItemDef i = itemDefMapper.selectOneById(id);
        if (i == null) throw new BusinessException(404, "商品不存在");

        long refCount = userItemMapper.selectCountByQuery(
                QueryWrapper.create().eq("item_def_id", id));
        if (refCount > 0) {
            throw new BusinessException("该商品已被 " + refCount + " 个用户持有，无法删除（请先下架或清库存）");
        }

        itemDefMapper.deleteById(id);
    }
}
