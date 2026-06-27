package com.petgrowup.study.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.study.dto.NodeDTO;
import com.petgrowup.study.dto.SubjectProgressDTO;
import com.petgrowup.study.dto.WorldMapDTO;
import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.entity.StudyRecord;
import com.petgrowup.study.entity.StudySession;
import com.petgrowup.study.entity.SubjectWorld;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import com.petgrowup.study.mapper.StudyRecordMapper;
import com.petgrowup.study.mapper.StudySessionMapper;
import com.petgrowup.study.mapper.SubjectWorldMapper;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class SubjectWorldService {

    private final SubjectWorldMapper worldMapper;
    private final KnowledgeNodeMapper knowledgeNodeMapper;
    private final StudySessionMapper sessionMapper;
    private final StudyRecordMapper recordMapper;

    public SubjectWorldService(SubjectWorldMapper worldMapper, KnowledgeNodeMapper knowledgeNodeMapper,
                               StudySessionMapper sessionMapper, StudyRecordMapper recordMapper) {
        this.worldMapper = worldMapper;
        this.knowledgeNodeMapper = knowledgeNodeMapper;
        this.sessionMapper = sessionMapper;
        this.recordMapper = recordMapper;
    }

    public WorldMapDTO getWorldMap(Long userId, String subject) {
        SubjectWorld world = worldMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("subject", subject));

        List<KnowledgeNode> nodes = knowledgeNodeMapper.selectListByQuery(
                QueryWrapper.create().eq("subject", subject).orderBy("order_index", true));

        Set<Long> completedNodeIds = getCompletedNodeIds(userId, subject);
        Map<Long, Integer> nodeStars = getNodeStarRatings(userId, subject);

        List<NodeDTO> nodeDTOs = new ArrayList<>();
        for (int i = 0; i < nodes.size(); i++) {
            KnowledgeNode node = nodes.get(i);
            boolean isCompleted = completedNodeIds.contains(node.getId());
            boolean isUnlocked = i == 0 || completedNodeIds.contains(nodes.get(i - 1).getId());
            nodeDTOs.add(NodeDTO.builder()
                    .nodeId(node.getId())
                    .name(node.getName())
                    .description(node.getDescription())
                    .difficulty(node.getDifficulty())
                    .isUnlocked(isUnlocked)
                    .isCompleted(isCompleted)
                    .starRating(nodeStars.getOrDefault(node.getId(), 0))
                    .build());
        }

        return WorldMapDTO.builder()
                .subject(subject)
                .worldLevel(world != null ? world.getWorldLevel() : 1)
                .nodes(nodeDTOs)
                .build();
    }

    public SubjectProgressDTO getProgress(Long userId, String subject) {
        List<KnowledgeNode> allNodes = knowledgeNodeMapper.selectListByQuery(
                QueryWrapper.create().eq("subject", subject));

        SubjectWorld world = worldMapper.selectOneByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("subject", subject));

        Set<Long> completedNodeIds = getCompletedNodeIds(userId, subject);

        List<StudySession> completedSessions = sessionMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("subject", subject)
                        .eq("status", "COMPLETED"));

        double accuracyAverage = completedSessions.stream()
                .filter(s -> s.getAccuracy() != null)
                .mapToDouble(s -> s.getAccuracy().doubleValue())
                .average()
                .orElse(0.0);

        return SubjectProgressDTO.builder()
                .subject(subject)
                .worldLevel(world != null ? world.getWorldLevel() : 1)
                .totalStars(world != null ? world.getTotalStars() : 0)
                .completedNodes(completedNodeIds.size())
                .totalNodes(allNodes.size())
                .accuracyAverage(accuracyAverage)
                .build();
    }

    public List<SubjectProgressDTO> getProgressList(Long userId) {
        return Arrays.asList("chinese", "math", "english").stream()
                .map(subject -> getProgress(userId, subject))
                .collect(Collectors.toList());
    }

    private Set<Long> getCompletedNodeIds(Long userId, String subject) {
        List<StudySession> completedSessions = sessionMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("subject", subject)
                        .eq("status", "COMPLETED"));

        if (completedSessions.isEmpty()) {
            return Collections.emptySet();
        }

        List<Long> sessionIds = completedSessions.stream()
                .map(StudySession::getId)
                .collect(Collectors.toList());

        return recordMapper.selectListByQuery(
                        QueryWrapper.create().in("session_id", sessionIds))
                .stream()
                .map(StudyRecord::getKnowledgeNodeId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    private Map<Long, Integer> getNodeStarRatings(Long userId, String subject) {
        List<StudySession> completedSessions = sessionMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("subject", subject)
                        .eq("status", "COMPLETED"));

        if (completedSessions.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<Long, StudySession> sessionMap = completedSessions.stream()
                .collect(Collectors.toMap(StudySession::getId, s -> s));

        List<Long> sessionIds = completedSessions.stream()
                .map(StudySession::getId)
                .collect(Collectors.toList());

        List<StudyRecord> records = recordMapper.selectListByQuery(
                QueryWrapper.create().in("session_id", sessionIds));

        // Group best accuracy by knowledge node
        Map<Long, Double> bestAccuracyByNode = new HashMap<>();
        for (StudyRecord record : records) {
            if (record.getKnowledgeNodeId() == null) continue;
            StudySession s = sessionMap.get(record.getSessionId());
            if (s == null || s.getAccuracy() == null) continue;
            double acc = s.getAccuracy().doubleValue();
            bestAccuracyByNode.merge(record.getKnowledgeNodeId(), acc, Math::max);
        }

        Map<Long, Integer> starRatings = new HashMap<>();
        for (Map.Entry<Long, Double> entry : bestAccuracyByNode.entrySet()) {
            double acc = entry.getValue();
            int stars;
            if (acc >= 0.8) stars = 3;
            else if (acc >= 0.6) stars = 2;
            else if (acc >= 0.4) stars = 1;
            else stars = 0;
            starRatings.put(entry.getKey(), stars);
        }
        return starRatings;
    }
}
