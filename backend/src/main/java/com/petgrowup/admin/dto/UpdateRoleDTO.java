package com.petgrowup.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class UpdateRoleDTO {
    @NotBlank
    @Pattern(regexp = "STUDENT|ADMIN", message = "角色只能为 STUDENT 或 ADMIN")
    private String role;
}
