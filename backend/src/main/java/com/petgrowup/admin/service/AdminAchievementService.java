package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.AchievementPageDTO.AchievementRowDTO;
import com.petgrowup.achievement.entity.AchievementDef;
import com.petgrowup.achievement.mapper.AchievementDefMapper;
import com.petgrowup.common.exception.BusinessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminAchievementService {

    private final AchievementDefMapper mapper;

    public AdminAchievementService(AchievementDefMapper mapper) {
        this.mapper = mapper;
    }

    public AchievementPageDTO list(AchievementFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getCategory() != null && !filter.getCategory().isBlank()) {
            qw.eq("category", filter.getCategory());
        }
        if (filter.getRarity() != null && !filter.getRarity().isBlank()) {
            qw.eq("rarity", filter.getRarity());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("name", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);

        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("display_order", true);

        List<AchievementDef> list = mapper.selectListByQuery(qw);
        List<AchievementRowDTO> rows = list.stream().map(e -> AchievementRowDTO.builder()
                .id(e.getId()).achievementKey(e.getAchievementKey()).category(e.getCategory())
                .name(e.getName()).description(e.getDescription()).iconUrl(e.getIconUrl())
                .rarity(e.getRarity()).requirementType(e.getRequirementType())
                .requirementThreshold(e.getRequirementThreshold()).subject(e.getSubject())
                .rewardEnergy(e.getRewardEnergy()).rewardItemKey(e.getRewardItemKey())
                .rewardTitle(e.getRewardTitle()).displayOrder(e.getDisplayOrder())
                .isHidden(e.getIsHidden()).createdAt(e.getCreatedAt()).build()
        ).collect(Collectors.toList());

        return AchievementPageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public AchievementDef get(Long id) {
        AchievementDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "成就不存在");
        return e;
    }

    @Transactional
    public AchievementDef create(CreateAchievementDTO dto) {
        long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("achievement_key", dto.getAchievementKey()));
        if (existing > 0) throw new BusinessException("成就标识 " + dto.getAchievementKey() + " 已存在");

        AchievementDef e = AchievementDef.builder()
                .achievementKey(dto.getAchievementKey()).category(dto.getCategory())
                .name(dto.getName()).description(dto.getDescription()).iconUrl(dto.getIconUrl())
                .rarity(dto.getRarity()).requirementType(dto.getRequirementType())
                .requirementThreshold(dto.getRequirementThreshold()).subject(dto.getSubject())
                .rewardEnergy(dto.getRewardEnergy() != null ? dto.getRewardEnergy() : 0L)
                .rewardItemKey(dto.getRewardItemKey()).rewardTitle(dto.getRewardTitle())
                .displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .isHidden(dto.getIsHidden() != null ? dto.getIsHidden() : false)
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public AchievementDef update(Long id, UpdateAchievementDTO dto) {
        AchievementDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "成就不存在");

        if (dto.getAchievementKey() != null) {
            if (!dto.getAchievementKey().equals(e.getAchievementKey())) {
                long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("achievement_key", dto.getAchievementKey()));
                if (existing > 0) throw new BusinessException("成就标识 " + dto.getAchievementKey() + " 已存在");
            }
            e.setAchievementKey(dto.getAchievementKey());
        }
        if (dto.getCategory() != null) e.setCategory(dto.getCategory());
        if (dto.getName() != null) e.setName(dto.getName());
        if (dto.getDescription() != null) e.setDescription(dto.getDescription());
        if (dto.getIconUrl() != null) e.setIconUrl(dto.getIconUrl());
        if (dto.getRarity() != null) e.setRarity(dto.getRarity());
        if (dto.getRequirementType() != null) e.setRequirementType(dto.getRequirementType());
        if (dto.getRequirementThreshold() != null) e.setRequirementThreshold(dto.getRequirementThreshold());
        if (dto.getSubject() != null) e.setSubject(dto.getSubject());
        if (dto.getRewardEnergy() != null) e.setRewardEnergy(dto.getRewardEnergy());
        if (dto.getRewardItemKey() != null) e.setRewardItemKey(dto.getRewardItemKey());
        if (dto.getRewardTitle() != null) e.setRewardTitle(dto.getRewardTitle());
        if (dto.getDisplayOrder() != null) e.setDisplayOrder(dto.getDisplayOrder());
        if (dto.getIsHidden() != null) e.setIsHidden(dto.getIsHidden());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "成就不存在");
        mapper.deleteById(id);
    }
}
