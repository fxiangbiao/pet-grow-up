package com.petgrowup.admin.dto;

import lombok.Data;

@Data
public class UpdateStoryDTO {
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
}