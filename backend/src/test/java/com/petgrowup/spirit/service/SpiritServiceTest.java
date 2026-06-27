package com.petgrowup.spirit.service;

import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.achievement.service.AchievementService;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.story.service.StoryService;
import com.petgrowup.spirit.dto.ChooseSpiritRequest;
import com.petgrowup.spirit.dto.PersonalityDTO;
import com.petgrowup.spirit.entity.LearningSpirit;
import com.petgrowup.spirit.entity.SpiritSpecies;
import com.petgrowup.spirit.mapper.SpiritMapper;
import com.petgrowup.spirit.mapper.SpiritSpeciesMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.mockito.ArgumentCaptor;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatcher;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SpiritServiceTest {

    @Mock
    private SpiritMapper spiritMapper;
    @Mock
    private SpiritSpeciesMapper speciesMapper;
    @Mock
    private UserMapper userMapper;
    @Mock
    private EnergyService energyService;
    @Mock
    private AchievementService achievementService;
    @Mock
    private ObjectMapper objectMapper;
    @Mock
    private StoryService storyService;

    private SpiritService spiritService;

    @BeforeEach
    void setUp() {
        spiritService = new SpiritService(spiritMapper, speciesMapper, userMapper, energyService, achievementService, objectMapper, storyService);
    }

    @Test
    void chooseStarterSpirit_shouldSucceed() throws Exception {
        when(objectMapper.writeValueAsString(any())).thenReturn("{}");
        when(spiritMapper.selectCountByQuery(any())).thenReturn(0L);
        when(speciesMapper.selectOneById(1L)).thenReturn(
                SpiritSpecies.builder().id(1L).name("Test Spirit").subject("chinese").evolutionStage(1).build());
        when(userMapper.selectOneById(1L)).thenReturn(User.builder().id(1L).build());
        when(spiritMapper.insert(any())).thenReturn(1);

        ChooseSpiritRequest request = new ChooseSpiritRequest();
        request.setSpeciesId(1L);
        request.setNickname("My Spirit");

        assertDoesNotThrow(() -> spiritService.chooseStarterSpirit(1L, request));
        verify(spiritMapper).insert(any());
    }

    @Test
    void chooseStarterSpirit_shouldThrowWhenAlreadyHasSpirit() {
        when(spiritMapper.selectCountByQuery(any())).thenReturn(1L);

        ChooseSpiritRequest request = new ChooseSpiritRequest();
        request.setSpeciesId(1L);
        request.setNickname("My Spirit");

        assertThrows(BusinessException.class, () -> spiritService.chooseStarterSpirit(1L, request));
    }

    @Test
    void feedSpirit_shouldIncreaseStats() {
        LearningSpirit spirit = LearningSpirit.builder().id(1L).userId(1L).happiness(50).energy(50).build();
        when(spiritMapper.selectOneById(1L)).thenReturn(spirit);

        spiritService.feedSpirit(1L, 1L, 30L);

        // feed adds energyAmount/5 = 6 to both happiness and energy
        verify(spiritMapper).update(argThat(s -> {
            assertEquals(56, s.getHappiness());
            assertEquals(56, s.getEnergy());
            return true;
        }));
        verify(energyService).spendEnergy(anyLong(), anyLong(), anyString());
    }

    @Test
    void feedSpirit_shouldCapStatsAt100() {
        LearningSpirit spirit = LearningSpirit.builder().id(1L).userId(1L).happiness(98).energy(99).build();
        when(spiritMapper.selectOneById(1L)).thenReturn(spirit);

        spiritService.feedSpirit(1L, 1L, 30L);

        verify(spiritMapper).update(argThat(s -> {
            assertEquals(100, s.getHappiness());
            assertEquals(100, s.getEnergy());
            return true;
        }));
    }

    @Test
    void chooseStarter_shouldInitializePersonality() throws Exception {
        ObjectMapper realMapper = new ObjectMapper();
        when(objectMapper.writeValueAsString(any(PersonalityDTO.class))).thenAnswer(inv ->
            realMapper.writeValueAsString(inv.getArgument(0)));
        when(spiritMapper.selectCountByQuery(any())).thenReturn(0L);
        when(speciesMapper.selectOneById(1L)).thenReturn(
                SpiritSpecies.builder().id(1L).name("Test Spirit").subject("chinese").evolutionStage(1).build());
        when(userMapper.selectOneById(1L)).thenReturn(User.builder().id(1L).build());
        when(spiritMapper.insert(any())).thenReturn(1);

        ChooseSpiritRequest request = new ChooseSpiritRequest();
        request.setSpeciesId(1L);
        request.setNickname("My Spirit");

        spiritService.chooseStarterSpirit(1L, request);

        ArgumentCaptor<LearningSpirit> captor = ArgumentCaptor.forClass(LearningSpirit.class);
        verify(spiritMapper).insert(captor.capture());
        PersonalityDTO p = realMapper.readValue(captor.getValue().getPersonality(), PersonalityDTO.class);
        assertEquals(50, p.getLively());
        assertEquals(50, p.getShy());
        assertEquals(50, p.getIndependent());
        assertEquals(50, p.getPlayful());
        assertEquals(50, p.getGentle());
        assertEquals(50, p.getBrave());
    }

    @Test
    void updatePersonalityAfterStudy_shouldAdjustScores() throws Exception {
        ObjectMapper realMapper = new ObjectMapper();
        String initialJson = realMapper.writeValueAsString(PersonalityDTO.defaultPersonality());
        LearningSpirit spirit = LearningSpirit.builder().id(1L).userId(1L).personality(initialJson).build();

        when(spiritMapper.selectOneById(1L)).thenReturn(spirit);
        when(objectMapper.readValue(initialJson, PersonalityDTO.class)).thenReturn(PersonalityDTO.defaultPersonality());
        when(objectMapper.writeValueAsString(any(PersonalityDTO.class))).thenAnswer(inv ->
            realMapper.writeValueAsString(inv.getArgument(0)));

        // High accuracy (≥80%): brave+2, lively+1
        spiritService.updatePersonalityAfterStudy(1L, 0.85, 100, 120, 1);

        ArgumentCaptor<LearningSpirit> captor = ArgumentCaptor.forClass(LearningSpirit.class);
        verify(spiritMapper).update(captor.capture());
        PersonalityDTO result = realMapper.readValue(captor.getValue().getPersonality(), PersonalityDTO.class);
        assertEquals(52, result.getBrave());
        assertEquals(51, result.getLively());
        assertEquals(50, result.getShy());
        assertEquals(50, result.getIndependent());
        assertEquals(50, result.getPlayful());
        assertEquals(50, result.getGentle());
    }

    @Test
    void updatePersonality_shouldClampToBounds() throws Exception {
        ObjectMapper realMapper = new ObjectMapper();
        PersonalityDTO nearMax = PersonalityDTO.builder()
                .lively(99).shy(50).independent(50).playful(50).gentle(50).brave(99).build();
        String initialJson = realMapper.writeValueAsString(nearMax);
        LearningSpirit spirit = LearningSpirit.builder().id(1L).userId(1L).personality(initialJson).build();

        when(spiritMapper.selectOneById(1L)).thenReturn(spirit);
        when(objectMapper.readValue(initialJson, PersonalityDTO.class)).thenReturn(nearMax);
        when(objectMapper.writeValueAsString(any(PersonalityDTO.class))).thenAnswer(inv ->
            realMapper.writeValueAsString(inv.getArgument(0)));

        // High accuracy: brave+2 (99→101→100), lively+1 (99→100)
        spiritService.updatePersonalityAfterStudy(1L, 0.85, 100, 120, 1);

        ArgumentCaptor<LearningSpirit> captor = ArgumentCaptor.forClass(LearningSpirit.class);
        verify(spiritMapper).update(captor.capture());
        PersonalityDTO result = realMapper.readValue(captor.getValue().getPersonality(), PersonalityDTO.class);
        assertEquals(100, result.getBrave());
        assertEquals(100, result.getLively());
    }
}
