package com.petgrowup.spirit.entity;

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
@Table("personality_dimension")
public class PersonalityDimension {

    @Id(keyType = KeyType.Auto)
    private Long id;

    private String dimensionKey;

    private String name;

    private String description;
}
