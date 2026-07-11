package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.DailyRewardPageDTO.DailyRewardRowDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.daily.entity.DailyRewardDef;
import com.petgrowup.daily.mapper.DailyRewardDefMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminDailyRewardService {

    private final DailyRewardDefMapper mapper;

    public AdminDailyRewardService(DailyRewardDefMapper mapper) {
        this.mapper = mapper;
    }

    public DailyRewardPageDTO list(DailyRewardFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getRewardType() != null && !filter.getRewardType().isBlank()) {
            qw.eq("reward_type", filter.getRewardType());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("name", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("display_order", true);

        List<DailyRewardDef> list = mapper.selectListByQuery(qw);
        List<DailyRewardRowDTO> rows = list.stream().map(e -> DailyRewardRowDTO.builder()
                .id(e.getId()).rewardKey(e.getRewardKey()).name(e.getName())
                .description(e.getDescription()).rewardType(e.getRewardType())
                .rewardValue(e.getRewardValue()).rewardItemKey(e.getRewardItemKey())
                .unlockDay(e.getUnlockDay()).iconUrl(e.getIconUrl())
                .displayOrder(e.getDisplayOrder()).createdAt(e.getCreatedAt()).build()
        ).collect(Collectors.toList());

        return DailyRewardPageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public DailyRewardDef get(Long id) {
        DailyRewardDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "每日奖励不存在");
        return e;
    }

    @Transactional
    public DailyRewardDef create(CreateDailyRewardDTO dto) {
        long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("reward_key", dto.getRewardKey()));
        if (existing > 0) throw new BusinessException("奖励标识 " + dto.getRewardKey() + " 已存在");

        DailyRewardDef e = DailyRewardDef.builder()
                .rewardKey(dto.getRewardKey()).name(dto.getName()).description(dto.getDescription())
                .rewardType(dto.getRewardType()).rewardValue(dto.getRewardValue())
                .rewardItemKey(dto.getRewardItemKey()).unlockDay(dto.getUnlockDay())
                .iconUrl(dto.getIconUrl()).displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public DailyRewardDef update(Long id, UpdateDailyRewardDTO dto) {
        DailyRewardDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "每日奖励不存在");

        if (dto.getRewardKey() != null) {
            if (!dto.getRewardKey().equals(e.getRewardKey())) {
                long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("reward_key", dto.getRewardKey()));
                if (existing > 0) throw new BusinessException("奖励标识 " + dto.getRewardKey() + " 已存在");
            }
            e.setRewardKey(dto.getRewardKey());
        }
        if (dto.getName() != null) e.setName(dto.getName());
        if (dto.getDescription() != null) e.setDescription(dto.getDescription());
        if (dto.getRewardType() != null) e.setRewardType(dto.getRewardType());
        if (dto.getRewardValue() != null) e.setRewardValue(dto.getRewardValue());
        if (dto.getRewardItemKey() != null) e.setRewardItemKey(dto.getRewardItemKey());
        if (dto.getUnlockDay() != null) e.setUnlockDay(dto.getUnlockDay());
        if (dto.getIconUrl() != null) e.setIconUrl(dto.getIconUrl());
        if (dto.getDisplayOrder() != null) e.setDisplayOrder(dto.getDisplayOrder());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "每日奖励不存在");
        mapper.deleteById(id);
    }
}
