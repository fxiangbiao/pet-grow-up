package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.dto.StoryPageDTO.StoryRowDTO;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.story.entity.StoryChapter;
import com.petgrowup.story.mapper.StoryChapterMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminStoryService {

    private final StoryChapterMapper mapper;

    public AdminStoryService(StoryChapterMapper mapper) {
        this.mapper = mapper;
    }

    public StoryPageDTO list(StoryFilterDTO filter) {
        QueryWrapper qw = QueryWrapper.create();

        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            qw.like("title", "%" + filter.getKeyword() + "%");
        }

        long total = mapper.selectCountByQuery(qw);
        int page = Math.max(1, filter.getPage() != null ? filter.getPage() : 1);
        int size = Math.max(1, Math.min(100, filter.getSize() != null ? filter.getSize() : 20));
        qw.limit(size).offset((page - 1) * size);
        qw.orderBy("display_order", true);

        List<StoryChapter> list = mapper.selectListByQuery(qw);
        List<StoryRowDTO> rows = list.stream().map(e -> StoryRowDTO.builder()
                .id(e.getId()).chapterNumber(e.getChapterNumber()).title(e.getTitle())
                .narrative(e.getNarrative()).npcName(e.getNpcName()).npcDialogue(e.getNpcDialogue())
                .choiceText(e.getChoiceText()).requirementType(e.getRequirementType())
                .requirementValue(e.getRequirementValue()).rewardEnergy(e.getRewardEnergy())
                .displayOrder(e.getDisplayOrder()).build()
        ).collect(Collectors.toList());

        return StoryPageDTO.builder().items(rows).total(total).page(page).size(size).build();
    }

    public StoryChapter get(Long id) {
        StoryChapter e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "章节不存在");
        return e;
    }

    @Transactional
    public StoryChapter create(CreateStoryDTO dto) {
        StoryChapter e = StoryChapter.builder()
                .chapterNumber(dto.getChapterNumber()).title(dto.getTitle())
                .narrative(dto.getNarrative()).npcName(dto.getNpcName()).npcDialogue(dto.getNpcDialogue())
                .choiceText(dto.getChoiceText()).requirementType(dto.getRequirementType())
                .requirementValue(dto.getRequirementValue() != null ? dto.getRequirementValue() : 1)
                .rewardEnergy(dto.getRewardEnergy() != null ? dto.getRewardEnergy() : 0L)
                .displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .build();
        mapper.insert(e);
        return e;
    }

    @Transactional
    public StoryChapter update(Long id, UpdateStoryDTO dto) {
        StoryChapter e = mapper.selectOneById(id);
        if (e == null) throw new BusinessException(404, "章节不存在");

        if (dto.getChapterNumber() != null) e.setChapterNumber(dto.getChapterNumber());
        if (dto.getTitle() != null) e.setTitle(dto.getTitle());
        if (dto.getNarrative() != null) e.setNarrative(dto.getNarrative());
        if (dto.getNpcName() != null) e.setNpcName(dto.getNpcName());
        if (dto.getNpcDialogue() != null) e.setNpcDialogue(dto.getNpcDialogue());
        if (dto.getChoiceText() != null) e.setChoiceText(dto.getChoiceText());
        if (dto.getRequirementType() != null) e.setRequirementType(dto.getRequirementType());
        if (dto.getRequirementValue() != null) e.setRequirementValue(dto.getRequirementValue());
        if (dto.getRewardEnergy() != null) e.setRewardEnergy(dto.getRewardEnergy());
        if (dto.getDisplayOrder() != null) e.setDisplayOrder(dto.getDisplayOrder());

        mapper.update(e);
        return e;
    }

    @Transactional
    public void delete(Long id) {
        if (mapper.selectOneById(id) == null) throw new BusinessException(404, "章节不存在");
        mapper.deleteById(id);
    }
}
