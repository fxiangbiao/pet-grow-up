package com.petgrowup.admin.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ResetPasswordDTO {
    @Size(min = 6, max = 20, message = "密码长度需在 6-20 之间")
    private String newPassword;
}
