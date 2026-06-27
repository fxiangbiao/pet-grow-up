package com.petgrowup.story.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("story_chapter")
public class StoryChapter {
    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("chapter_number")
    private Integer chapterNumber;

    private String title;
    private String narrative;

    @Column("npc_name")
    private String npcName;

    @Column("npc_dialogue")
    private String npcDialogue;

    @Column("choice_text")
    private String choiceText;

    @Column("requirement_type")
    private String requirementType;

    @Column("requirement_value")
    private Integer requirementValue;

    @Column("reward_energy")
    private Long rewardEnergy;

    @Column("display_order")
    private Integer displayOrder;
}
