package com.petgrowup.story.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class ChapterDTO {
    private Long id;
    private Integer chapterNumber;
    private String title;
    private String narrative;
    private String npcName;
    private String npcDialogue;
    private String choiceText;
    private String requirementType;
    private Integer requirementValue;
    private Long rewardEnergy;
    private Integer displayOrder;
    private boolean unlocked;
    private boolean completed;
    private boolean rewardClaimed;
}
