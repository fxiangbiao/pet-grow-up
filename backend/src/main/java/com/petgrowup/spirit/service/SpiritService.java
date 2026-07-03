package com.petgrowup.spirit.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.achievement.enums.RequirementType;
import com.petgrowup.achievement.service.AchievementService;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.common.exception.ResourceNotFoundException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.story.service.StoryService;
import com.petgrowup.spirit.dto.*;
import com.petgrowup.spirit.entity.LearningSpirit;
import com.petgrowup.spirit.entity.SpiritSpecies;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import com.petgrowup.spirit.entity.SpiritAccessory;
import com.petgrowup.spirit.mapper.SpiritMapper;
import com.petgrowup.spirit.mapper.SpiritSpeciesMapper;
import com.petgrowup.spirit.mapper.SpiritAccessoryMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SpiritService {

    private final SpiritMapper spiritMapper;
    private final SpiritSpeciesMapper speciesMapper;
    private final UserMapper userMapper;
    private final EnergyService energyService;
    private final AchievementService achievementService;
    private final StoryService storyService;
    private final SpiritAccessoryMapper accessoryMapper;
    private final ItemDefMapper itemDefMapper;
    private final UserItemMapper userItemMapper;
    private final ObjectMapper objectMapper;

    public SpiritService(SpiritMapper spiritMapper, SpiritSpeciesMapper speciesMapper,
                         UserMapper userMapper, EnergyService energyService,
                         AchievementService achievementService, ObjectMapper objectMapper,
                         StoryService storyService,
                         SpiritAccessoryMapper accessoryMapper,
                         ItemDefMapper itemDefMapper,
                         UserItemMapper userItemMapper) {
        this.spiritMapper = spiritMapper;
        this.speciesMapper = speciesMapper;
        this.userMapper = userMapper;
        this.energyService = energyService;
        this.achievementService = achievementService;
        this.objectMapper = objectMapper;
        this.storyService = storyService;
        this.accessoryMapper = accessoryMapper;
        this.itemDefMapper = itemDefMapper;
        this.userItemMapper = userItemMapper;
    }

    public List<SpiritSpeciesDTO> getAvailableSpecies() {
        List<SpiritSpecies> species = speciesMapper.selectListByQuery(
                QueryWrapper.create().eq("evolution_stage", 1));
        return species.stream().map(this::toSpeciesDTO).collect(Collectors.toList());
    }

    public List<SpiritDTO> getUserSpirits(Long userId) {
        List<LearningSpirit> spirits = spiritMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));
        return spirits.stream().map(this::toSpiritDTO).collect(Collectors.toList());
    }

    public SpiritDTO getSpiritDetail(Long spiritId) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null) throw new ResourceNotFoundException("Spirit", spiritId);
        return toSpiritDTO(spirit);
    }

    @Transactional
    public SpiritDTO chooseStarterSpirit(Long userId, ChooseSpiritRequest request) {
        long count = spiritMapper.selectCountByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (count > 0) {
            throw new BusinessException("已经拥有精灵了");
        }

        SpiritSpecies species = speciesMapper.selectOneById(request.getSpeciesId());
        if (species == null) throw new ResourceNotFoundException("Species", request.getSpeciesId());
        if (species.getEvolutionStage() != 1) {
            throw new BusinessException("只能选择初始形态的精灵");
        }

        PersonalityDTO initialPersonality = PersonalityDTO.fromArchetype(request.getPersonalityType());

        String personalityJson;
        try {
            personalityJson = objectMapper.writeValueAsString(initialPersonality);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize personality", e);
        }

        LearningSpirit spirit = LearningSpirit.builder()
                .userId(userId)
                .speciesId(request.getSpeciesId())
                .nickname(request.getNickname())
                .currentEvolutionStage(1)
                .happiness(60)
                .energy(50)
                .personality(personalityJson)
                .isActive(true)
                .obtainedAt(LocalDateTime.now())
                .build();

        spiritMapper.insert(spirit);

        User user = userMapper.selectOneById(userId);
        user.setCurrentSpiritId(spirit.getId());
        userMapper.update(user);

        return toSpiritDTO(spirit);
    }

    @Transactional
    public SpiritDTO feedSpirit(Long userId, Long spiritId, long energyAmount) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null) throw new ResourceNotFoundException("Spirit", spiritId);
        if (!spirit.getUserId().equals(userId)) throw new BusinessException("这不是你的精灵");

        energyService.spendEnergy(userId, energyAmount, "feed");

        spirit.setHappiness(Math.min(100, spirit.getHappiness() + (int)(energyAmount / 5)));
        spirit.setEnergy(Math.min(100, spirit.getEnergy() + (int)(energyAmount / 5)));
        spiritMapper.update(spirit);

        return toSpiritDTO(spirit);
    }

    @Transactional
    public SpiritDTO evolveSpirit(Long userId, Long spiritId) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null) throw new ResourceNotFoundException("Spirit", spiritId);
        if (!spirit.getUserId().equals(userId)) throw new BusinessException("这不是你的精灵");

        SpiritSpecies currentSpecies = speciesMapper.selectOneById(spirit.getSpeciesId());
        if (currentSpecies == null) throw new ResourceNotFoundException("Species", spirit.getSpeciesId());

        // Find next evolution stage
        SpiritSpecies nextSpecies = speciesMapper.selectOneByQuery(
                QueryWrapper.create()
                        .eq("evolves_from_id", currentSpecies.getId()));
        if (nextSpecies == null) throw new BusinessException("这只精灵已达到最高形态");

        // Check energy cost
        if (nextSpecies.getEvolutionEnergyCost() != null) {
            energyService.spendEnergy(userId, nextSpecies.getEvolutionEnergyCost(), "evolve");
        }

        spirit.setSpeciesId(nextSpecies.getId());
        spirit.setCurrentEvolutionStage(nextSpecies.getEvolutionStage());
        spiritMapper.update(spirit);

        achievementService.checkAndUnlock(userId, RequirementType.FIRST_EVOLUTION, Map.of());
        storyService.checkAllConditions(userId);

        return toSpiritDTO(spirit);
    }

    @Transactional
    public SpiritDTO activateSpirit(Long userId, Long spiritId) {
        // Deactivate all others
        LearningSpirit deactivateAll = LearningSpirit.builder().isActive(false).build();
        spiritMapper.updateByQuery(deactivateAll, QueryWrapper.create().eq("user_id", userId));

        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null) throw new ResourceNotFoundException("Spirit", spiritId);
        if (!spirit.getUserId().equals(userId)) throw new BusinessException("这不是你的精灵");

        spirit.setIsActive(true);
        spiritMapper.update(spirit);

        User user = userMapper.selectOneById(userId);
        user.setCurrentSpiritId(spiritId);
        userMapper.update(user);

        return toSpiritDTO(spirit);
    }

    public void updateAffection(Long spiritId, int delta) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit != null) {
            spirit.setAffection(Math.max(0, spirit.getAffection() + delta));
            spiritMapper.update(spirit);
        }
    }

    public PersonalityDTO getPersonality(Long spiritId) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null || spirit.getPersonality() == null) {
            return PersonalityDTO.defaultPersonality();
        }
        return parsePersonality(spirit.getPersonality());
    }

    /**
     * Compute dormancy status for a user's active spirit.
     */
    public SpiritStatusDTO getSpiritStatus(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null || user.getCurrentSpiritId() == null) {
            return SpiritStatusDTO.builder()
                    .dormancyLevel(0)
                    .lastStudyDate(null)
                    .daysSinceLastStudy(0)
                    .personalityType(null)
                    .build();
        }

        LearningSpirit spirit = spiritMapper.selectOneById(user.getCurrentSpiritId());
        if (spirit == null) {
            return SpiritStatusDTO.builder()
                    .dormancyLevel(0)
                    .lastStudyDate(null)
                    .daysSinceLastStudy(0)
                    .personalityType(null)
                    .build();
        }

        LocalDate lastStudy = user.getLastStudyDate();
        long daysSince = 0;
        int dormancyLevel = 0;

        if (lastStudy != null) {
            daysSince = java.time.temporal.ChronoUnit.DAYS.between(lastStudy, LocalDate.now());
            if (daysSince >= 3) {
                dormancyLevel = 2; // sleeping
            } else if (daysSince >= 1) {
                dormancyLevel = 1; // dim
            }
        }

        // Determine personality type string from dimensions
        PersonalityDTO p = parsePersonality(spirit.getPersonality());
        String personalityType = inferPersonalityType(p);

        return SpiritStatusDTO.builder()
                .dormancyLevel(dormancyLevel)
                .lastStudyDate(lastStudy)
                .daysSinceLastStudy(daysSince)
                .personalityType(personalityType)
                .build();
    }

    /**
     * Infer the closest personality archetype from dimension scores.
     */
    private String inferPersonalityType(PersonalityDTO p) {
        if (p == null) return "cheerful";
        int cheerful = p.getLively() + p.getPlayful();
        int gentle = p.getGentle() + p.getShy();
        int tsundere = p.getIndependent() + p.getShy();
        int brave = p.getBrave() + p.getLively();

        if (cheerful >= gentle && cheerful >= tsundere && cheerful >= brave) return "cheerful";
        if (gentle >= cheerful && gentle >= tsundere && gentle >= brave) return "gentle";
        if (tsundere >= cheerful && tsundere >= gentle && tsundere >= brave) return "tsundere";
        return "brave";
    }

    public void updatePersonalityAfterStudy(Long spiritId, double accuracy, int actualDuration, int expectedDuration, int streak) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null || spirit.getPersonality() == null) return;

        PersonalityDTO p = parsePersonality(spirit.getPersonality());
        if (p == null) return;

        // High accuracy: brave +2, lively +1
        if (accuracy >= 0.8) {
            p.setBrave(clamp(p.getBrave() + 2));
            p.setLively(clamp(p.getLively() + 1));
        }
        // Low accuracy: gentle +2, playful +1
        else if (accuracy < 0.6) {
            p.setGentle(clamp(p.getGentle() + 2));
            p.setPlayful(clamp(p.getPlayful() + 1));
        }
        // Medium accuracy: gentle +1
        else {
            p.setGentle(clamp(p.getGentle() + 1));
        }

        // Consecutive study streak: independent +2
        if (streak >= 3) {
            p.setIndependent(clamp(p.getIndependent() + 2));
        }

        // Fast completion: lively +2
        if (expectedDuration > 0 && actualDuration < expectedDuration * 0.5) {
            p.setLively(clamp(p.getLively() + 2));
        }

        try {
            spirit.setPersonality(objectMapper.writeValueAsString(p));
            spiritMapper.update(spirit);
        } catch (JsonProcessingException e) {
            // Log and skip personality update on failure
        }
    }

    public String getSpiritReaction(Long spiritId, double accuracy) {
        PersonalityDTO p = getPersonality(spiritId);
        return computeReaction(p, accuracy);
    }

    private String computeReaction(PersonalityDTO p, double accuracy) {
        boolean isBrave = p.getBrave() >= 60;
        boolean isLively = p.getLively() >= 60;
        boolean isGentle = p.getGentle() >= 60;
        boolean isShy = p.getShy() >= 60;
        boolean isPlayful = p.getPlayful() >= 60;

        if (accuracy >= 0.95) {
            if (isLively) return "EXCITED_BOUNCE";
            if (isBrave) return "PROUD_ROAR";
            return "EXCITED";
        }
        if (accuracy >= 0.80) {
            if (isPlayful) return "PLAYFUL_CELEBRATE";
            if (isLively) return "HAPPY_DANCE";
            return "HAPPY";
        }
        if (accuracy >= 0.60) {
            if (isGentle) return "GENTLE_SMILE";
            if (isShy) return "SHY_NOD";
            return "CONTENT";
        }
        if (accuracy >= 0.40) {
            if (isBrave) return "BRAVE_ENCOURAGE";
            if (isGentle) return "GENTLE_COMFORT";
            return "ENCOURAGING";
        }
        if (isShy) return "SHY_LOOK_AWAY";
        if (isPlayful) return "PLAYFUL_GROAN";
        return "TIRED";
    }

    private PersonalityDTO parsePersonality(String json) {
        try {
            return objectMapper.readValue(json, PersonalityDTO.class);
        } catch (JsonProcessingException e) {
            return PersonalityDTO.defaultPersonality();
        }
    }

    private int clamp(int value) {
        return Math.max(0, Math.min(100, value));
    }

    private SpiritDTO toSpiritDTO(LearningSpirit spirit) {
        SpiritSpecies species = speciesMapper.selectOneById(spirit.getSpeciesId());
        return SpiritDTO.builder()
                .id(spirit.getId())
                .species(toSpeciesDTO(species))
                .nickname(spirit.getNickname())
                .currentEvolutionStage(spirit.getCurrentEvolutionStage())
                .happiness(spirit.getHappiness())
                .energy(spirit.getEnergy())
                .affection(spirit.getAffection())
                .isActive(spirit.getIsActive())
                .personality(parsePersonality(spirit.getPersonality()))
                .build();
    }

    private SpiritSpeciesDTO toSpeciesDTO(SpiritSpecies species) {
        if (species == null) return null;
        return SpiritSpeciesDTO.builder()
                .id(species.getId())
                .speciesKey(species.getSpeciesKey())
                .name(species.getName())
                .subject(species.getSubject())
                .description(species.getDescription())
                .evolutionStage(species.getEvolutionStage())
                .evolvesFromId(species.getEvolvesFromId())
                .evolutionEnergyCost(species.getEvolutionEnergyCost())
                .spriteUrl(species.getSpriteUrl())
                .build();
    }

    // ── Sprint E: Accessory management ──

    public List<AccessoryDTO> getEquippedAccessories(Long spiritId) {
        List<SpiritAccessory> equipped = accessoryMapper.selectListByQuery(
                QueryWrapper.create().eq("spirit_id", spiritId));
        return equipped.stream().map(a -> {
            ItemDef item = itemDefMapper.selectOneById(a.getItemDefId());
            if (item == null) return null;
            return AccessoryDTO.builder()
                    .slot(a.getSlot())
                    .itemKey(item.getItemKey())
                    .name(item.getName())
                    .iconUrl(item.getIconUrl())
                    .rarity(inferRarity(item))
                    .build();
        }).filter(java.util.Objects::nonNull).collect(Collectors.toList());
    }

    @Transactional
    public List<AccessoryDTO> equipAccessory(Long spiritId, String slot, Long itemDefId) {
        LearningSpirit spirit = spiritMapper.selectOneById(spiritId);
        if (spirit == null) throw new ResourceNotFoundException("Spirit", spiritId);

        // Validate item exists and is an accessory
        ItemDef item = itemDefMapper.selectOneById(itemDefId);
        if (item == null) throw new ResourceNotFoundException("Item", itemDefId);
        if (!"ACCESSORY".equals(item.getCategory()))
            throw new BusinessException("只能装备配饰类物品");

        // Check user owns this item
        User owner = userMapper.selectOneById(spirit.getUserId());
        UserItem existing = userItemMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", owner.getId()).eq("item_def_id", itemDefId));
        if (existing == null || existing.getQuantity() <= 0)
            throw new BusinessException("你还没有这个配饰");

        // Upsert: remove existing accessory in same slot, then insert new
        accessoryMapper.deleteByQuery(
                QueryWrapper.create().eq("spirit_id", spiritId).eq("slot", slot));

        SpiritAccessory sa = SpiritAccessory.builder()
                .spiritId(spiritId)
                .slot(slot)
                .itemDefId(itemDefId)
                .build();
        accessoryMapper.insert(sa);

        return getEquippedAccessories(spiritId);
    }

    @Transactional
    public List<AccessoryDTO> unequipAccessory(Long spiritId, String slot) {
        accessoryMapper.deleteByQuery(
                QueryWrapper.create().eq("spirit_id", spiritId).eq("slot", slot));
        return getEquippedAccessories(spiritId);
    }

    private String inferRarity(ItemDef item) {
        if (item.getItemKey() == null) return "common";
        if (item.getItemKey().contains("rainbow") || item.getItemKey().contains("perseverance")) return "epic";
        if (item.getItemKey().contains("effect_") || item.getItemKey().contains("star_shades")
                || item.getItemKey().contains("graduation")) return "rare";
        return "common";
    }
}
