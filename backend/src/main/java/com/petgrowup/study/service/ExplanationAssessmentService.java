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
            encouragement = "Amazing! You explained it so clearly! You're a true little teacher!";
        } else if (score >= 0.5) {
            encouragement = "Great job! You covered the key points. Keep practicing!";
        } else {
            encouragement = "Good try! Let's review the key points together.";
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