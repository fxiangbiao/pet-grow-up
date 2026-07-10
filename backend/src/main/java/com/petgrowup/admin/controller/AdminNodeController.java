package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminNodeService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.entity.KnowledgeNode;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminNodeController {

    private final AdminNodeService adminNodeService;

    public AdminNodeController(AdminNodeService adminNodeService) {
        this.adminNodeService = adminNodeService;
    }

    @GetMapping("/nodes/tree")
    public ApiResponse<List<NodeTreeDTO>> getTree() {
        return ApiResponse.success(adminNodeService.getTree());
    }

    @GetMapping("/nodes/{id}")
    public ApiResponse<KnowledgeNode> getNode(@PathVariable Long id) {
        return ApiResponse.success(adminNodeService.getNode(id));
    }

    @PostMapping("/nodes")
    public ApiResponse<KnowledgeNode> createNode(@Valid @RequestBody CreateNodeDTO dto) {
        return ApiResponse.success(adminNodeService.createNode(dto));
    }

    @PutMapping("/nodes/{id}")
    public ApiResponse<KnowledgeNode> updateNode(@PathVariable Long id,
                                                  @RequestBody UpdateNodeDTO dto) {
        return ApiResponse.success(adminNodeService.updateNode(id, dto));
    }

    @DeleteMapping("/nodes/{id}")
    public ApiResponse<Void> deleteNode(@PathVariable Long id) {
        adminNodeService.deleteNode(id);
        return ApiResponse.success(null);
    }

    @PutMapping("/nodes/reorder")
    public ApiResponse<Void> reorderNodes(@RequestBody ReorderNodesDTO dto) {
        adminNodeService.reorderNodes(dto);
        return ApiResponse.success(null);
    }
}
