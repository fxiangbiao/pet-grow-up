package com.petgrowup.study.entity;

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
@Table("knowledge_node")
public class KnowledgeNode {

    @Id(keyType = KeyType.Auto)
    private Long id;

    private String subject;

    @Column("node_key")
    private String nodeKey;

    private String name;

    @Column(isLarge = true)
    private String description;

    private Integer difficulty;

    @Column("grade_level")
    private Integer gradeLevel;

    @Column("parent_node_id")
    private Long parentNodeId;

    @Column(value = "prerequisite_nodes", isLarge = true)
    private String prerequisiteNodes;

    @Column(value = "content_template", isLarge = true)
    private String contentTemplate;

    @Column("order_index")
    private Integer orderIndex;
}
