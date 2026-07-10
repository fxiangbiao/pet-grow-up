package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.*;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.study.entity.KnowledgeNode;
import com.petgrowup.study.mapper.KnowledgeNodeMapper;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminNodeService {

    private final KnowledgeNodeMapper nodeMapper;
    private final QuizQuestionMapper questionMapper;

    public AdminNodeService(KnowledgeNodeMapper nodeMapper, QuizQuestionMapper questionMapper) {
        this.nodeMapper = nodeMapper;
        this.questionMapper = questionMapper;
    }

    public List<NodeTreeDTO> getTree() {
        List<KnowledgeNode> allNodes = nodeMapper.selectListByQuery(QueryWrapper.create());
        Map<Long, List<KnowledgeNode>> byParent = allNodes.stream()
                .collect(Collectors.groupingBy(n ->
                        n.getParentNodeId() != null ? n.getParentNodeId() : 0L));

        // Count questions per node
        Map<Long, Integer> questionCounts = new HashMap<>();
        for (KnowledgeNode node : allNodes) {
            long count = questionMapper.selectCountByQuery(
                    QueryWrapper.create().eq("knowledge_node_id", node.getId()));
            questionCounts.put(node.getId(), (int) count);
        }

        // Build trees grouped by subject
        Map<String, List<NodeTreeDTO>> bySubject = new LinkedHashMap<>();
        for (KnowledgeNode node : allNodes) {
            if (node.getParentNodeId() == null) {
                bySubject.computeIfAbsent(node.getSubject(), k -> new ArrayList<>())
                        .add(buildTree(node, byParent, questionCounts));
            }
        }

        // Return flat list of root nodes (frontend groups by subject)
        List<NodeTreeDTO> result = new ArrayList<>();
        for (Map.Entry<String, List<NodeTreeDTO>> entry : bySubject.entrySet()) {
            for (NodeTreeDTO root : entry.getValue()) {
                result.add(root);
            }
        }
        return result;
    }

    private NodeTreeDTO buildTree(KnowledgeNode node, Map<Long, List<KnowledgeNode>> byParent,
                                   Map<Long, Integer> questionCounts) {
        List<KnowledgeNode> children = byParent.getOrDefault(node.getId(), Collections.emptyList());
        List<NodeTreeDTO> childDTOs = children.stream()
                .map(c -> buildTree(c, byParent, questionCounts))
                .sorted(Comparator.comparingInt(n -> n.getOrderIndex() != null ? n.getOrderIndex() : 0))
                .collect(Collectors.toList());

        return NodeTreeDTO.builder()
                .id(node.getId())
                .nodeKey(node.getNodeKey())
                .name(node.getName())
                .description(node.getDescription())
                .difficulty(node.getDifficulty())
                .gradeLevel(node.getGradeLevel())
                .orderIndex(node.getOrderIndex())
                .subject(node.getSubject())
                .parentNodeId(node.getParentNodeId())
                .questionCount(questionCounts.getOrDefault(node.getId(), 0))
                .children(childDTOs.isEmpty() ? null : childDTOs)
                .build();
    }

    public KnowledgeNode getNode(Long id) {
        KnowledgeNode node = nodeMapper.selectOneById(id);
        if (node == null) throw new BusinessException(404, "知识节点不存在");
        return node;
    }

    @Transactional
    public KnowledgeNode createNode(CreateNodeDTO dto) {
        KnowledgeNode node = KnowledgeNode.builder()
                .subject(dto.getSubject())
                .nodeKey(dto.getNodeKey())
                .name(dto.getName())
                .description(dto.getDescription())
                .difficulty(dto.getDifficulty() != null ? dto.getDifficulty() : 1)
                .gradeLevel(dto.getGradeLevel() != null ? dto.getGradeLevel() : 1)
                .parentNodeId(dto.getParentNodeId())
                .prerequisiteNodes(dto.getPrerequisiteNodes())
                .orderIndex(dto.getOrderIndex() != null ? dto.getOrderIndex() : 0)
                .build();
        nodeMapper.insert(node);
        return node;
    }

    @Transactional
    public KnowledgeNode updateNode(Long id, UpdateNodeDTO dto) {
        KnowledgeNode node = nodeMapper.selectOneById(id);
        if (node == null) throw new BusinessException(404, "知识节点不存在");

        if (dto.getNodeKey() != null) node.setNodeKey(dto.getNodeKey());
        if (dto.getName() != null) node.setName(dto.getName());
        if (dto.getDescription() != null) node.setDescription(dto.getDescription());
        if (dto.getDifficulty() != null) node.setDifficulty(dto.getDifficulty());
        if (dto.getGradeLevel() != null) node.setGradeLevel(dto.getGradeLevel());
        if (dto.getParentNodeId() != null) node.setParentNodeId(dto.getParentNodeId());
        if (dto.getPrerequisiteNodes() != null) node.setPrerequisiteNodes(dto.getPrerequisiteNodes());
        if (dto.getOrderIndex() != null) node.setOrderIndex(dto.getOrderIndex());

        nodeMapper.update(node);
        return node;
    }

    @Transactional
    public void deleteNode(Long id) {
        KnowledgeNode node = nodeMapper.selectOneById(id);
        if (node == null) throw new BusinessException(404, "知识节点不存在");

        // Check for children
        long childCount = nodeMapper.selectCountByQuery(
                QueryWrapper.create().eq("parent_node_id", id));
        if (childCount > 0) {
            throw new BusinessException("该节点下有 " + childCount + " 个子节点，请先删除子节点");
        }

        // Check for questions
        long questionCount = questionMapper.selectCountByQuery(
                QueryWrapper.create().eq("knowledge_node_id", id));
        if (questionCount > 0) {
            throw new BusinessException("该节点下有 " + questionCount + " 道题目，请先删除或转移题目");
        }

        nodeMapper.deleteById(id);
    }

    @Transactional
    public void reorderNodes(ReorderNodesDTO dto) {
        List<KnowledgeNode> siblings;
        if (dto.getParentNodeId() != null) {
            siblings = nodeMapper.selectListByQuery(
                    QueryWrapper.create().eq("parent_node_id", dto.getParentNodeId()));
        } else {
            siblings = nodeMapper.selectListByQuery(
                    QueryWrapper.create().eq("subject", dto.getSubject()).isNull("parent_node_id"));
        }

        Map<Long, KnowledgeNode> nodeMap = siblings.stream()
                .collect(Collectors.toMap(KnowledgeNode::getId, n -> n));

        for (int i = 0; i < dto.getOrderedNodeIds().size(); i++) {
            Long nodeId = dto.getOrderedNodeIds().get(i);
            KnowledgeNode node = nodeMap.get(nodeId);
            if (node != null) {
                node.setOrderIndex(i);
                nodeMapper.update(node);
            }
        }
    }
}
