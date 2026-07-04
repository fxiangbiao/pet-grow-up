package com.petgrowup.room.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.room.dto.PetRoomDTO;
import com.petgrowup.room.dto.PetRoomDTO.PlacedItemDTO;
import com.petgrowup.room.dto.PlaceItemRequest;
import com.petgrowup.room.dto.RemoveItemRequest;
import com.petgrowup.room.dto.UpdatePositionRequest;
import com.petgrowup.room.entity.PetRoom;
import com.petgrowup.room.entity.RoomThemeDef;
import com.petgrowup.room.mapper.PetRoomMapper;
import com.petgrowup.room.mapper.RoomThemeDefMapper;
import com.petgrowup.shop.entity.ItemDef;
import com.petgrowup.shop.entity.UserItem;
import com.petgrowup.shop.mapper.ItemDefMapper;
import com.petgrowup.shop.mapper.UserItemMapper;
import com.petgrowup.spirit.service.SpiritService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class PetRoomService {

    private final PetRoomMapper petRoomMapper;
    private final UserMapper userMapper;
    private final UserItemMapper userItemMapper;
    private final ItemDefMapper itemDefMapper;
    private final SpiritService spiritService;
    private final RoomThemeDefMapper roomThemeDefMapper;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public PetRoomService(PetRoomMapper petRoomMapper, UserMapper userMapper,
                          UserItemMapper userItemMapper, ItemDefMapper itemDefMapper,
                          SpiritService spiritService, RoomThemeDefMapper roomThemeDefMapper) {
        this.petRoomMapper = petRoomMapper;
        this.userMapper = userMapper;
        this.userItemMapper = userItemMapper;
        this.itemDefMapper = itemDefMapper;
        this.spiritService = spiritService;
        this.roomThemeDefMapper = roomThemeDefMapper;
    }

    public PetRoomDTO getRoom(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        PetRoom room = findOrCreateRoom(userId);
        List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());

        // Resolve theme info
        RoomThemeDef theme = roomThemeDefMapper.selectOneByQuery(
                QueryWrapper.create().eq("theme_key", room.getRoomStyle()));
        String themeName = theme != null ? theme.getName() : "温馨暖居";
        String themeIcon = theme != null ? theme.getIconUrl() : "🏠";

        // Build furniture list from slot data
        List<PlacedItemDTO> furniture = new ArrayList<>();
        for (Map<String, Object> entry : slotList) {
            Number itemDefIdNum = (Number) entry.get("itemDefId");
            if (itemDefIdNum == null) continue;
            ItemDef item = itemDefMapper.selectOneById(itemDefIdNum.longValue());
            if (item != null) {
                Number x = (Number) entry.getOrDefault("x", 200.0);
                Number y = (Number) entry.getOrDefault("y", 220.0);
                Number userItemId = (Number) entry.get("userItemId");
                furniture.add(PlacedItemDTO.builder()
                        .itemDefId(item.getId())
                        .userItemId(userItemId != null ? userItemId.longValue() : null)
                        .itemKey(item.getItemKey())
                        .name(item.getName())
                        .iconUrl(item.getIconUrl())
                        .category(item.getCategory())
                        .x(x.doubleValue())
                        .y(y.doubleValue())
                        .build());
            }
        }

        return PetRoomDTO.builder()
                .id(room.getId())
                .roomStyle(room.getRoomStyle())
                .themeName(themeName)
                .themeIcon(themeIcon)
                .furniture(furniture)
                .activeSpirit(user.getCurrentSpiritId() != null
                        ? spiritService.getSpiritDetail(user.getCurrentSpiritId()) : null)
                .build();
    }

    @Transactional
    public PetRoomDTO placeItem(Long userId, PlaceItemRequest req) {
        // Validate ownership
        UserItem userItem = userItemMapper.selectOneById(req.getUserItemId());
        if (userItem == null || !userItem.getUserId().equals(userId))
            throw new BusinessException("物品不存在或不属于你");
        ItemDef item = itemDefMapper.selectOneById(userItem.getItemDefId());
        if (item == null || !"DECORATION".equals(item.getCategory()))
            throw new BusinessException("该物品不是装饰品");
        if (userItem.getQuantity() <= 0)
            throw new BusinessException("物品数量不足");

        PetRoom room = findOrCreateRoom(userId);
        List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());

        // Add new furniture entry with position
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("userItemId", req.getUserItemId());
        entry.put("itemDefId", item.getId());
        entry.put("itemKey", item.getItemKey());
        entry.put("x", req.getX() != null ? req.getX() : 200.0);
        entry.put("y", req.getY() != null ? req.getY() : 220.0);
        slotList.add(entry);

        room.setSlotData(toJson(slotList));
        petRoomMapper.update(room);

        return getRoom(userId);
    }

    @Transactional
    public PetRoomDTO removeItem(Long userId, Long userItemId) {
        PetRoom room = petRoomMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (room == null) return getRoom(userId);

        List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());
        slotList.removeIf(entry -> {
            Number uid = (Number) entry.get("userItemId");
            return uid != null && uid.longValue() == userItemId;
        });

        room.setSlotData(toJson(slotList));
        petRoomMapper.update(room);

        return getRoom(userId);
    }

    @Transactional
    public PetRoomDTO updatePosition(Long userId, UpdatePositionRequest req) {
        PetRoom room = petRoomMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (room == null) throw new BusinessException("房间不存在");

        List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());
        for (Map<String, Object> entry : slotList) {
            Number uid = (Number) entry.get("userItemId");
            if (uid != null && uid.longValue() == req.getUserItemId()) {
                entry.put("x", req.getX());
                entry.put("y", req.getY());
                break;
            }
        }

        room.setSlotData(toJson(slotList));
        petRoomMapper.update(room);

        return getRoom(userId);
    }

    @Transactional
    public PetRoomDTO changeTheme(Long userId, String themeKey) {
        // Verify theme exists
        RoomThemeDef theme = roomThemeDefMapper.selectOneByQuery(
                QueryWrapper.create().eq("theme_key", themeKey));
        if (theme == null) throw new BusinessException("主题不存在");

        PetRoom room = findOrCreateRoom(userId);
        room.setRoomStyle(themeKey);
        petRoomMapper.update(room);

        return getRoom(userId);
    }

    public List<PlacedItemDTO> getAvailableDecorations(Long userId) {
        List<UserItem> userItems = userItemMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId));

        List<PlacedItemDTO> decorations = new ArrayList<>();
        for (UserItem ui : userItems) {
            if (ui.getQuantity() <= 0) continue;
            ItemDef item = itemDefMapper.selectOneById(ui.getItemDefId());
            if (item != null && "DECORATION".equals(item.getCategory())) {
                decorations.add(PlacedItemDTO.builder()
                        .itemDefId(item.getId())
                        .userItemId(ui.getId())
                        .itemKey(item.getItemKey())
                        .name(item.getName())
                        .iconUrl(item.getIconUrl())
                        .category(item.getCategory())
                        .build());
            }
        }
        return decorations;
    }

    private PetRoom findOrCreateRoom(Long userId) {
        PetRoom room = petRoomMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId));
        if (room == null) {
            room = PetRoom.builder()
                    .userId(userId)
                    .roomStyle("cozy_warm")
                    .slotData("[]")
                    .build();
            petRoomMapper.insert(room);
        }
        return room;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> parseSlotData(String json) {
        if (json == null || json.isBlank()) return new ArrayList<>();
        try {
            // New format: [{"userItemId":..., "itemDefId":..., "x":..., "y":...}]
            if (json.trim().startsWith("[")) {
                return objectMapper.readValue(json,
                    new TypeReference<List<Map<String, Object>>>() {});
            }
            // Legacy format: {"slot_key": itemDefId} — migrate to empty
            return new ArrayList<>();
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }

    private String toJson(List<Map<String, Object>> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }
}
