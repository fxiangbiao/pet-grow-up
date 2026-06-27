package com.petgrowup.spirit.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("spirit_species")
public class SpiritSpecies {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("species_key")
    private String speciesKey;

    private String name;

    private String subject;

    @Column(isLarge = true)
    private String description;

    @Column("evolution_stage")
    private Integer evolutionStage;

    @Column("evolves_from_id")
    private Long evolvesFromId;

    @Column("evolution_energy_cost")
    private Long evolutionEnergyCost;

    @Column("base_affection")
    private Integer baseAffection;

    @Column("sprite_url")
    private String spriteUrl;

    @Column(value = "animation_data", isLarge = true)
    private String animationData;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
