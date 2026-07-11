package com.petgrowup.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoryPageDTO {
    private List<StoryRowDTO> items;
    private long total;
    private int page;
    private int size;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StoryRowDTO {
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
    }
}