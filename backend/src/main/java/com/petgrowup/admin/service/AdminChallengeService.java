package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.ChallengePageDTO.ChallengeRowDTO;
import com.petgrowup.challenge.entity.DailyChallengeDef;
import com.petgrowup.challenge.mapper.DailyChallengeDefMapper;
import com.petgrowup.common.exception.BusinessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminChallengeService {

    private final DailyChallengeDefMapper mapper;

    public AdminChallengeService(DailyChallengeDefMapper mapper) {
        this.mapper = mapper;
    }

    public ChallengePageDTO list(ChallengeFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getChallengeType() != null && !filter.getChallengeType().isBlank()) {
            qw.eq("challenge_type", filter.getChallengeType());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("description", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("display_order", true);

        List<DailyChallengeDef> list = mapper.selectListByQuery(qw);
        List<ChallengeRowDTO> rows = list.stream().map(e -> ChallengeRowDTO.builder()
                .id(e.getId()).challengeType(e.getChallengeType()).description(e.getDescription())
                .targetValue(e.getTargetValue()).rewardEnergy(e.getRewardEnergy())
                .iconUrl(e.getIconUrl()).displayOrder(e.getDisplayOrder())
                .createdAt(e.getCreatedAt()).build()
        ).collect(Collectors.toList());

        return ChallengePageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public DailyChallengeDef get(Long id) {
        DailyChallengeDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "挑战不存在");
        return e;
    }

    @Transactional
    public DailyChallengeDef create(CreateChallengeDTO dto) {
        DailyChallengeDef e = DailyChallengeDef.builder()
                .challengeType(dto.getChallengeType()).description(dto.getDescription())
                .targetValue(dto.getTargetValue() != null ? dto.getTargetValue() : 1)
                .rewardEnergy(dto.getRewardEnergy() != null ? dto.getRewardEnergy() : 0L)
                .iconUrl(dto.getIconUrl()).displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public DailyChallengeDef update(Long id, UpdateChallengeDTO dto) {
        DailyChallengeDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "挑战不存在");

        if (dto.getChallengeType() != null) e.setChallengeType(dto.getChallengeType());
        if (dto.getDescription() != null) e.setDescription(dto.getDescription());
        if (dto.getTargetValue() != null) e.setTargetValue(dto.getTargetValue());
        if (dto.getRewardEnergy() != null) e.setRewardEnergy(dto.getRewardEnergy());
        if (dto.getIconUrl() != null) e.setIconUrl(dto.getIconUrl());
        if (dto.getDisplayOrder() != null) e.setDisplayOrder(dto.getDisplayOrder());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "挑战不存在");
        mapper.deleteById(id);
    }
}
