package com.petgrowup.admin.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.admin.dto.AchievementStatsDTO;
import com.petgrowup.admin.dto.AchievementStatsDTO.AchievementStatRowDTO;
import com.petgrowup.admin.dto.EnergyStatsDTO;
import com.petgrowup.admin.dto.OverviewDTO;
import com.petgrowup.admin.dto.SourceBreakdownDTO;
import com.petgrowup.admin.dto.StudyStatsDTO;
import com.petgrowup.admin.dto.TimeSeriesPointDTO;
import com.petgrowup.admin.mapper.AdminStatisticsMapper;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.energy.mapper.EnergyTransactionMapper;
import com.petgrowup.study.mapper.QuizQuestionMapper;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class AdminStatisticsService {

    private static final int MAX_DAYS = 90;

    private final AdminStatisticsMapper statsMapper;
    private final UserMapper userMapper;
    private final QuizQuestionMapper questionMapper;
    private final StudySessionMapper sessionMapper;
    private final EnergyTransactionMapper energyMapper;

    public AdminStatisticsService(AdminStatisticsMapper statsMapper,
                                  UserMapper userMapper,
                                  QuizQuestionMapper questionMapper,
                                  StudySessionMapper sessionMapper,
                                  EnergyTransactionMapper energyMapper) {
        this.statsMapper = statsMapper;
        this.userMapper = userMapper;
        this.questionMapper = questionMapper;
        this.sessionMapper = sessionMapper;
        this.energyMapper = energyMapper;
    }

    public OverviewDTO getOverview() {
        long totalUsers = userMapper.selectCountByQuery(QueryWrapper.create());
        long totalStudents = userMapper.selectCountByQuery(QueryWrapper.create().eq("role", "STUDENT"));
        long totalAdmins = userMapper.selectCountByQuery(QueryWrapper.create().eq("role", "ADMIN"));
        long totalQuestions = questionMapper.selectCountByQuery(QueryWrapper.create());
        long totalSessions = sessionMapper.selectCountByQuery(QueryWrapper.create());

        Long totalEarned = energyMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(SUM(amount), 0)")
                        .eq("transaction_type", "EARN"),
                Long.class);
        Long totalSpent = energyMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(SUM(ABS(amount)), 0)")
                        .eq("transaction_type", "SPEND"),
                Long.class);

        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        long todayActiveUsers = sessionMapper.selectCountByQuery(
                QueryWrapper.create()
                        .ge("started_at", todayStart)
                        .select("DISTINCT user_id"));

        return OverviewDTO.builder()
                .totalUsers(totalUsers)
                .totalStudents(totalStudents)
                .totalAdmins(totalAdmins)
                .totalQuestions(totalQuestions)
                .totalStudySessions(totalSessions)
                .totalEnergyEarned(totalEarned != null ? totalEarned : 0L)
                .totalEnergySpent(totalSpent != null ? totalSpent : 0L)
                .todayActiveUsers(todayActiveUsers)
                .build();
    }

    public StudyStatsDTO getStudyStats(int days) {
        days = clampDays(days);
        return StudyStatsDTO.builder()
                .dailySessions(toTimeSeries(statsMapper.dailySessionCounts(days)))
                .dailyActiveUsers(toTimeSeries(statsMapper.dailyActiveUsers(days)))
                .avgAccuracy(toTimeSeries(statsMapper.dailyAvgAccuracy(days)))
                .build();
    }

    public EnergyStatsDTO getEnergyStats(int days) {
        days = clampDays(days);
        List<SourceBreakdownDTO> bySource = statsMapper.energyBySource().stream()
                .map(row -> SourceBreakdownDTO.builder()
                        .source(getString(row, "source"))
                        .totalAmount(getLong(row, "amt"))
                        .count(getLong(row, "cnt"))
                        .build())
                .toList();
        return EnergyStatsDTO.builder()
                .dailyEarned(toTimeSeries(statsMapper.dailyEnergyEarned(days)))
                .dailySpent(toTimeSeries(statsMapper.dailyEnergySpent(days)))
                .bySource(bySource)
                .build();
    }

    public AchievementStatsDTO getAchievementStats() {
        long totalUsers = userMapper.selectCountByQuery(QueryWrapper.create());
        if (totalUsers == 0) totalUsers = 1; // avoid division by zero

        long finalTotalUsers = totalUsers;
        List<AchievementStatRowDTO> rows = statsMapper.achievementUnlockCounts().stream()
                .map(row -> AchievementStatRowDTO.builder()
                        .key(getString(row, "k"))
                        .name(getString(row, "n"))
                        .category(getString(row, "cat"))
                        .rarity(getString(row, "r"))
                        .unlockedCount(getLong(row, "unlocked"))
                        .totalUsers(finalTotalUsers)
                        .unlockRate(getLong(row, "unlocked") * 100.0 / finalTotalUsers)
                        .build())
                .toList();
        return AchievementStatsDTO.builder().achievements(rows).build();
    }

    // ---- helpers ----

    private int clampDays(int days) {
        return Math.max(1, Math.min(MAX_DAYS, days));
    }

    private List<TimeSeriesPointDTO> toTimeSeries(List<Map<String, Object>> rows) {
        List<TimeSeriesPointDTO> result = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            result.add(TimeSeriesPointDTO.builder()
                    .date(getString(row, "d"))
                    .value(getLong(row, "c", "v"))
                    .build());
        }
        return result;
    }

    private String getString(Map<String, Object> row, String key) {
        Object val = row.get(key);
        return val != null ? val.toString() : "";
    }

    private long getLong(Map<String, Object> row, String... keys) {
        for (String key : keys) {
            Object val = row.get(key);
            if (val != null) {
                if (val instanceof Number n) return n.longValue();
                try { return Long.parseLong(val.toString()); } catch (NumberFormatException ignored) {}
            }
        }
        return 0L;
    }
}
