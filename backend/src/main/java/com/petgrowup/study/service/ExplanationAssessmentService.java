package com.petgrowup.study.service;

import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class ExplanationAssessmentService {

    private final KnowledgeNodeMapper knowledgeNodeMapper;

    public ExplanationAssessmentService(KnowledgeNodeMapper knowledgeNodeMapper) {
        this.knowledgeNodeMapper = knowledgeNodeMapper;
    }

    public Map<String, Object> assessExplanation(Long nodeId, String explanationText) {
        KnowledgeNode node = knowledgeNodeMapper.selectOneById(nodeId);
        if (node == null) {
            return null;
        }

        Set<String> keywords = extractKeywords(node.getName(), node.getDescription());

        String lowerText = explanationText.toLowerCase();
        List<String> found = new ArrayList<>();
        List<String> missing = new ArrayList<>();

        for (String keyword : keywords) {
            if (lowerText.contains(keyword.toLowerCase())) {
                found.add(keyword);
            } else {
                missing.add(keyword);
            }
        }

        double score = keywords.isEmpty() ? 0.5 : (double) found.size() / keywords.size();
        score = Math.min(1.0, Math.max(0.1, score));

        String encouragement;
        if (score >= 0.8) {
            encouragement = "哇！你讲解得太棒了！你是真正的小老师！";
        } else if (score >= 0.5) {
            encouragement = "做得好！你涵盖了关键知识点，继续加油！";
        } else {
            encouragement = "不错哦！让我们一起复习关键知识点吧！";
        }

        Map<String, Object> result = new HashMap<>();
        result.put("score", Math.round(score * 100));
        result.put("foundKeywords", found);
        result.put("missingKeywords", missing);
        result.put("encouragement", encouragement);
        result.put("energyReward", score >= 0.5 ? 15 : 5);
        return result;
    }

    private Set<String> extractKeywords(String name, String description) {
        Set<String> keywords = new LinkedHashSet<>();
        if (name != null) {
            for (String word : name.split("[\\s,;.!?]+")) {
                if (word.length() >= 2) keywords.add(word);
            }
            if (name.length() >= 2) keywords.add(name);
        }
        if (description != null) {
            for (String word : description.split("[\\s,;.!?]+")) {
                if (word.length() >= 2 && word.length() <= 15) keywords.add(word);
            }
        }
        return keywords;
    }
}