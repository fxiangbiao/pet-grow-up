package com.petgrowup.study.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.study.dto.WeaknessDTO;
import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.entity.LearningWeakness;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import com.petgrowup.study.mapper.WeaknessMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class WeaknessService {

    private final WeaknessMapper weaknessMapper;
    private final KnowledgeNodeMapper nodeMapper;

    public WeaknessService(WeaknessMapper weaknessMapper, KnowledgeNodeMapper nodeMapper) {
        this.weaknessMapper = weaknessMapper;
        this.nodeMapper = nodeMapper;
    }

    /**
     * Record a wrong answer: increment wrong_count, decrease mastery.
     */
    @Transactional
    public void recordWrongAnswer(Long userId, Long knowledgeNodeId, String subject) {
        LearningWeakness existing = weaknessMapper.selectOneByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("knowledge_node_id", knowledgeNodeId)
                        .eq("subject", subject));

        if (existing != null) {
            existing.setWrongCount(existing.getWrongCount() + 1);
            existing.setMasteryLevel(Math.max(0, existing.getMasteryLevel() - 5));
            existing.setLastWrongAt(LocalDateTime.now());
            weaknessMapper.update(existing);
        } else {
            LearningWeakness w = LearningWeakness.builder()
                    .userId(userId)
                    .knowledgeNodeId(knowledgeNodeId)
                    .subject(subject)
                    .wrongCount(1)
                    .masteryLevel(0)
                    .lastWrongAt(LocalDateTime.now())
                    .build();
            weaknessMapper.insert(w);
        }
    }

    /**
     * Record a correct answer: increase mastery.
     */
    @Transactional
    public void recordCorrectAnswer(Long userId, Long knowledgeNodeId, String subject) {
        LearningWeakness existing = weaknessMapper.selectOneByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("knowledge_node_id", knowledgeNodeId)
                        .eq("subject", subject));

        if (existing != null) {
            existing.setMasteryLevel(Math.min(100, existing.getMasteryLevel() + 10));
            weaknessMapper.update(existing);
        }
    }

    /**
     * Get user's weak knowledge points, sorted by mastery level ascending (weakest first).
     */
    public List<WeaknessDTO> getWeaknesses(Long userId, int limit) {
        List<LearningWeakness> weaknesses = weaknessMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .lt("mastery_level", 80)
                        .orderBy("mastery_level", true)
                        .orderBy("wrong_count", false)
                        .limit(limit));

        return weaknesses.stream().map(w -> {
            KnowledgeNode node = nodeMapper.selectOneById(w.getKnowledgeNodeId());
            String nodeName = node != null ? node.getName() : "未知知识点";
            return WeaknessDTO.builder()
                    .knowledgeNodeId(w.getKnowledgeNodeId())
                    .knowledgeNodeName(nodeName)
                    .subject(w.getSubject())
                    .wrongCount(w.getWrongCount())
                    .masteryLevel(w.getMasteryLevel())
                    .lastWrongAt(w.getLastWrongAt() != null ? w.getLastWrongAt().toString() : null)
                    .build();
        }).collect(Collectors.toList());
    }

    /**
     * Get the top weakness for a user (used for spirit reactions).
     */
    public WeaknessDTO getTopWeakness(Long userId) {
        List<WeaknessDTO> weaknesses = getWeaknesses(userId, 1);
        return weaknesses.isEmpty() ? null : weaknesses.get(0);
    }
}
