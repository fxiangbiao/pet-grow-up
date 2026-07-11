package com.petgrowup.admin.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * Statistics aggregation queries for the admin dashboard.
 * The project uses MyBatis-Flex with no XML mappers, so grouped aggregations
 * are defined here via {@link Select} annotations returning Map rows that the
 * service layer maps to DTOs.
 */
@Mapper
public interface AdminStatisticsMapper {

    // ---- Study session aggregations ----

    @Select("SELECT DATE(started_at) AS d, COUNT(*) AS c FROM study_session " +
            "WHERE started_at >= DATE_SUB(CURDATE(), INTERVAL #{days} DAY) " +
            "GROUP BY DATE(started_at) ORDER BY d")
    List<Map<String, Object>> dailySessionCounts(@Param("days") int days);

    @Select("SELECT DATE(started_at) AS d, COUNT(DISTINCT user_id) AS c FROM study_session " +
            "WHERE started_at >= DATE_SUB(CURDATE(), INTERVAL #{days} DAY) " +
            "GROUP BY DATE(started_at) ORDER BY d")
    List<Map<String, Object>> dailyActiveUsers(@Param("days") int days);

    @Select("SELECT DATE(started_at) AS d, COALESCE(AVG(accuracy), 0) AS v FROM study_session " +
            "WHERE started_at >= DATE_SUB(CURDATE(), INTERVAL #{days} DAY) " +
            "AND status = 'COMPLETED' " +
            "GROUP BY DATE(started_at) ORDER BY d")
    List<Map<String, Object>> dailyAvgAccuracy(@Param("days") int days);

    // ---- Energy transaction aggregations ----

    @Select("SELECT DATE(created_at) AS d, COALESCE(SUM(amount), 0) AS v FROM energy_transaction " +
            "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL #{days} DAY) " +
            "AND transaction_type = 'EARN' " +
            "GROUP BY DATE(created_at) ORDER BY d")
    List<Map<String, Object>> dailyEnergyEarned(@Param("days") int days);

    @Select("SELECT DATE(created_at) AS d, COALESCE(SUM(ABS(amount)), 0) AS v FROM energy_transaction " +
            "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL #{days} DAY) " +
            "AND transaction_type = 'SPEND' " +
            "GROUP BY DATE(created_at) ORDER BY d")
    List<Map<String, Object>> dailyEnergySpent(@Param("days") int days);

    @Select("SELECT source, COALESCE(SUM(amount), 0) AS amt, COUNT(*) AS cnt FROM energy_transaction " +
            "WHERE transaction_type = 'EARN' " +
            "GROUP BY source ORDER BY amt DESC")
    List<Map<String, Object>> energyBySource();

    // ---- Achievement aggregations ----

    @Select("SELECT a.achievement_key AS k, a.name AS n, a.category AS cat, a.rarity AS r, " +
            "COUNT(CASE WHEN ua.is_unlocked = TRUE THEN 1 END) AS unlocked " +
            "FROM achievement_def a " +
            "LEFT JOIN user_achievement ua ON ua.achievement_def_id = a.id " +
            "GROUP BY a.id, a.achievement_key, a.name, a.category, a.rarity " +
            "ORDER BY a.display_order")
    List<Map<String, Object>> achievementUnlockCounts();
}
