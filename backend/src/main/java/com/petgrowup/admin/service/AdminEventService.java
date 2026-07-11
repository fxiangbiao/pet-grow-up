package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.EventPageDTO.EventRowDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.event.entity.RandomEventDef;
import com.petgrowup.event.mapper.RandomEventDefMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminEventService {

    private final RandomEventDefMapper mapper;

    public AdminEventService(RandomEventDefMapper mapper) {
        this.mapper = mapper;
    }

    public EventPageDTO list(EventFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getEventType() != null && !filter.getEventType().isBlank()) {
            qw.eq("event_type", filter.getEventType());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("name", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("id", false);

        List<RandomEventDef> list = mapper.selectListByQuery(qw);
        List<EventRowDTO> rows = list.stream().map(e -> EventRowDTO.builder()
                .id(e.getId()).eventKey(e.getEventKey()).name(e.getName())
                .description(e.getDescription()).eventType(e.getEventType())
                .triggerChance(e.getTriggerChance()).minAccuracy(e.getMinAccuracy())
                .minStreak(e.getMinStreak()).rewardEnergy(e.getRewardEnergy())
                .rewardItemKey(e.getRewardItemKey()).rewardAffection(e.getRewardAffection())
                .displayText(e.getDisplayText()).iconUrl(e.getIconUrl())
                .createdAt(e.getCreatedAt()).build()
        ).collect(Collectors.toList());

        return EventPageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public RandomEventDef get(Long id) {
        RandomEventDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "事件不存在");
        return e;
    }

    @Transactional
    public RandomEventDef create(CreateEventDTO dto) {
        long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("event_key", dto.getEventKey()));
        if (existing > 0) throw new BusinessException("事件标识 " + dto.getEventKey() + " 已存在");

        RandomEventDef e = RandomEventDef.builder()
                .eventKey(dto.getEventKey()).name(dto.getName()).description(dto.getDescription())
                .eventType(dto.getEventType())
                .triggerChance(dto.getTriggerChance() != null ? dto.getTriggerChance() : new BigDecimal("0.10"))
                .minAccuracy(dto.getMinAccuracy() != null ? dto.getMinAccuracy() : BigDecimal.ZERO)
                .minStreak(dto.getMinStreak() != null ? dto.getMinStreak() : 0)
                .rewardEnergy(dto.getRewardEnergy() != null ? dto.getRewardEnergy() : 0L)
                .rewardItemKey(dto.getRewardItemKey())
                .rewardAffection(dto.getRewardAffection() != null ? dto.getRewardAffection() : 0)
                .displayText(dto.getDisplayText()).iconUrl(dto.getIconUrl())
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public RandomEventDef update(Long id, UpdateEventDTO dto) {
        RandomEventDef e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "事件不存在");

        if (dto.getEventKey() != null) {
            if (!dto.getEventKey().equals(e.getEventKey())) {
                long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("event_key", dto.getEventKey()));
                if (existing > 0) throw new BusinessException("事件标识 " + dto.getEventKey() + " 已存在");
            }
            e.setEventKey(dto.getEventKey());
        }
        if (dto.getName() != null) e.setName(dto.getName());
        if (dto.getDescription() != null) e.setDescription(dto.getDescription());
        if (dto.getEventType() != null) e.setEventType(dto.getEventType());
        if (dto.getTriggerChance() != null) e.setTriggerChance(dto.getTriggerChance());
        if (dto.getMinAccuracy() != null) e.setMinAccuracy(dto.getMinAccuracy());
        if (dto.getMinStreak() != null) e.setMinStreak(dto.getMinStreak());
        if (dto.getRewardEnergy() != null) e.setRewardEnergy(dto.getRewardEnergy());
        if (dto.getRewardItemKey() != null) e.setRewardItemKey(dto.getRewardItemKey());
        if (dto.getRewardAffection() != null) e.setRewardAffection(dto.getRewardAffection());
        if (dto.getDisplayText() != null) e.setDisplayText(dto.getDisplayText());
        if (dto.getIconUrl() != null) e.setIconUrl(dto.getIconUrl());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "事件不存在");
        mapper.deleteById(id);
    }
}
