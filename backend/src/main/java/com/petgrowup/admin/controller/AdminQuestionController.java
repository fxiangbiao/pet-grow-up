package com.petgrowup.admin.controller;

import com.petgrowup.admin.dto.*;
import com.petgrowup.admin.service.AdminQuestionService;
import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.study.entity.QuizQuestion;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminQuestionController {

    private final AdminQuestionService adminQuestionService;

    public AdminQuestionController(AdminQuestionService adminQuestionService) {
        this.adminQuestionService = adminQuestionService;
    }

    @GetMapping("/questions")
    public ApiResponse<QuestionPageDTO> listQuestions(@ModelAttribute QuestionFilterDTO filter) {
        return ApiResponse.success(adminQuestionService.listQuestions(filter));
    }

    @GetMapping("/questions/{id}")
    public ApiResponse<QuizQuestion> getQuestion(@PathVariable Long id) {
        return ApiResponse.success(adminQuestionService.getQuestion(id));
    }

    @PostMapping("/questions")
    public ApiResponse<QuizQuestion> createQuestion(@Valid @RequestBody CreateQuestionDTO dto) {
        return ApiResponse.success(adminQuestionService.createQuestion(dto));
    }

    @PutMapping("/questions/{id}")
    public ApiResponse<QuizQuestion> updateQuestion(@PathVariable Long id,
                                                     @RequestBody UpdateQuestionDTO dto) {
        return ApiResponse.success(adminQuestionService.updateQuestion(id, dto));
    }

    @DeleteMapping("/questions/{id}")
    public ApiResponse<Void> deleteQuestion(@PathVariable Long id) {
        adminQuestionService.deleteQuestion(id);
        return ApiResponse.success(null);
    }

    @PostMapping("/questions/batch-import")
    public ApiResponse<BatchImportResultDTO> batchImport(@RequestBody List<CreateQuestionDTO> questions) {
        return ApiResponse.success(adminQuestionService.batchImport(questions));
    }
}
