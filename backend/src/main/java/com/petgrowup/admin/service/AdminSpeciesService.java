package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.SpeciesPageDTO.SpeciesRowDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.spirit.entity.SpiritSpecies;
import com.petgrowup.spirit.mapper.SpiritSpeciesMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminSpeciesService {

    private final SpiritSpeciesMapper mapper;

    public AdminSpeciesService(SpiritSpeciesMapper mapper) {
        this.mapper = mapper;
    }

    public SpeciesPageDTO list(SpeciesFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getSubject() != null && !filter.getSubject().isBlank()) {
            qw.eq("subject", filter.getSubject());
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("name", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("id", true);

        List<SpiritSpecies> list = mapper.selectListByQuery(qw);
        List<SpeciesRowDTO> rows = list.stream().map(e -> SpeciesRowDTO.builder()
                .id(e.getId()).speciesKey(e.getSpeciesKey()).name(e.getName())
                .subject(e.getSubject()).description(e.getDescription())
                .evolutionStage(e.getEvolutionStage()).evolvesFromId(e.getEvolvesFromId())
                .evolutionEnergyCost(e.getEvolutionEnergyCost()).baseAffection(e.getBaseAffection())
                .spriteUrl(e.getSpriteUrl()).animationData(e.getAnimationData())
                .createdAt(e.getCreatedAt()).build()
        ).collect(Collectors.toList());

        return SpeciesPageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public SpiritSpecies get(Long id) {
        SpiritSpecies e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "物种不存在");
        return e;
    }

    @Transactional
    public SpiritSpecies create(CreateSpeciesDTO dto) {
        long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("species_key", dto.getSpeciesKey()));
        if (existing > 0) throw new BusinessException("物种标识 " + dto.getSpeciesKey() + " 已存在");

        SpiritSpecies e = SpiritSpecies.builder()
                .speciesKey(dto.getSpeciesKey()).name(dto.getName()).subject(dto.getSubject())
                .description(dto.getDescription())
                .evolutionStage(dto.getEvolutionStage() != null ? dto.getEvolutionStage() : 1)
                .evolvesFromId(dto.getEvolvesFromId()).evolutionEnergyCost(dto.getEvolutionEnergyCost())
                .baseAffection(dto.getBaseAffection() != null ? dto.getBaseAffection() : 0)
                .spriteUrl(dto.getSpriteUrl()).animationData(dto.getAnimationData())
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public SpiritSpecies update(Long id, UpdateSpeciesDTO dto) {
        SpiritSpecies e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "物种不存在");

        if (dto.getSpeciesKey() != null) {
            if (!dto.getSpeciesKey().equals(e.getSpeciesKey())) {
                long existing = mapper.selectCountByQuery(QueryWrapper.create().eq("species_key", dto.getSpeciesKey()));
                if (existing > 0) throw new BusinessException("物种标识 " + dto.getSpeciesKey() + " 已存在");
            }
            e.setSpeciesKey(dto.getSpeciesKey());
        }
        if (dto.getName() != null) e.setName(dto.getName());
        if (dto.getSubject() != null) e.setSubject(dto.getSubject());
        if (dto.getDescription() != null) e.setDescription(dto.getDescription());
        if (dto.getEvolutionStage() != null) e.setEvolutionStage(dto.getEvolutionStage());
        if (dto.getEvolvesFromId() != null) e.setEvolvesFromId(dto.getEvolvesFromId());
        if (dto.getEvolutionEnergyCost() != null) e.setEvolutionEnergyCost(dto.getEvolutionEnergyCost());
        if (dto.getBaseAffection() != null) e.setBaseAffection(dto.getBaseAffection());
        if (dto.getSpriteUrl() != null) e.setSpriteUrl(dto.getSpriteUrl());
        if (dto.getAnimationData() != null) e.setAnimationData(dto.getAnimationData());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "物种不存在");
        mapper.deleteById(id);
    }
}
