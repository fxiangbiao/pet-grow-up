package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateStoryDTO {
    @NotNull
    private Integer chapterNumber;

    @NotBlank
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