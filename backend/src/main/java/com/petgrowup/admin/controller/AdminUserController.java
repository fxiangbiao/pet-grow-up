package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.ResetPasswordDTO;
import com.petgrowup.admin.dto.UpdateRoleDTO;
import com.petgrowup.admin.dto.UserFilterDTO;
import com.petgrowup.admin.dto.UserPageDTO;
import com.petgrowup.admin.service.AdminUserService;
import com.petgrowup.auth.entity.User;
import com.petgrowup.common.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final AdminUserService adminUserService;

    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }

    @GetMapping("/users")
    public ApiResponse<UserPageDTO> listUsers(@ModelAttribute UserFilterDTO filter) {
        return ApiResponse.success(adminUserService.listUsers(filter));
    }

    @GetMapping("/users/{id}")
    public ApiResponse<User> getUser(@PathVariable Long id) {
        return ApiResponse.success(adminUserService.getUser(id));
    }

    @PutMapping("/users/{id}/role")
    public ApiResponse<User> updateRole(@PathVariable Long id,
                                        @Valid @RequestBody UpdateRoleDTO dto,
                                        @AuthenticationPrincipal Long currentUserId) {
        return ApiResponse.success(adminUserService.updateRole(id, dto, currentUserId));
    }

    @PostMapping("/users/{id}/reset-password")
    public ApiResponse<Void> resetPassword(@PathVariable Long id,
                                           @RequestBody(required = false) ResetPasswordDTO dto,
                                           @AuthenticationPrincipal Long currentUserId) {
        String newPassword = dto != null ? dto.getNewPassword() : null;
        adminUserService.resetPassword(id, newPassword, currentUserId);
        return ApiResponse.success(null);
    }
}
