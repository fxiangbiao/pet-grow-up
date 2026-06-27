package com.petgrowup.challenge.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.challenge.dto.DailyChallengeDTO;
import com.petgrowup.challenge.entity.DailyChallengeDef;
import com.petgrowup.challenge.entity.UserChallenge;
import com.petgrowup.challenge.mapper.DailyChallengeDefMapper;
import com.petgrowup.challenge.mapper.UserChallengeMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.energy.service.EnergyService;
import com.petgrowup.study.entity.StudySession;
import com.petgrowup.study.mapper.StudySessionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ChallengeService {

    private final DailyChallengeDefMapper challengeDefMapper;
    private final UserChallengeMapper userChallengeMapper;
    private final EnergyService energyService;
    private final StudySessionMapper studySessionMapper;

    public ChallengeService(DailyChallengeDefMapper challengeDefMapper,
                            UserChallengeMapper userChallengeMapper,
                            EnergyService energyService,
                            StudySessionMapper studySessionMapper) {
        this.challengeDefMapper = challengeDefMapper;
        this.userChallengeMapper = userChallengeMapper;
        this.energyService = energyService;
        this.studySessionMapper = studySessionMapper;
    }

    public List<DailyChallengeDTO> getTodayChallenges(Long userId) {
        LocalDate today = LocalDate.now();

        // Get all challenge definitions
        List<DailyChallengeDef> defs = challengeDefMapper.selectListByQuery(
                QueryWrapper.create().orderBy("display_order", true));

        // Get existing user progress for today
        List<UserChallenge> existing = userChallengeMapper.selectListByQuery(
                QueryWrapper.create().eq("user_id", userId).eq("challenge_date", today));

        Map<Long, UserChallenge> ucMap = existing.stream()
                .collect(Collectors.toMap(UserChallenge::getChallengeDefId, uc -> uc));

        // Create missing challenge records for today
        for (DailyChallengeDef def : defs) {
            if (!ucMap.containsKey(def.getId())) {
                UserChallenge uc = UserChallenge.builder()
                        .userId(userId)
                        .challengeDefId(def.getId())
                        .challengeDate(today)
                        .progress(0)
                        .completed(false)
                        .rewardClaimed(false)
                        .build();
                userChallengeMapper.insert(uc);
                ucMap.put(def.getId(), uc);
            }
        }

        // Build DTOs
        return defs.stream().map(def -> {
            UserChallenge uc = ucMap.get(def.getId());
            return DailyChallengeDTO.builder()
                    .id(uc != null ? uc.getId() : 0)
                    .challengeType(def.getChallengeType())
                    .description(def.getDescription())
                    .targetValue(def.getTargetValue())
                    .rewardEnergy(def.getRewardEnergy())
                    .iconUrl(def.getIconUrl())
                    .displayOrder(def.getDisplayOrder())
                    .progress(uc != null ? uc.getProgress() : 0)
                    .completed(uc != null ? uc.getCompleted() : false)
                    .rewardClaimed(uc != null ? uc.getRewardClaimed() : false)
                    .build();
        }).collect(Collectors.toList());
    }

    @Transactional
    public void updateProgress(Long userId, StudySession session) {
        LocalDate today = LocalDate.now();
        double accuracy = session.getAccuracy() != null ? session.getAccuracy().doubleValue() : 0.0;

        List<UserChallenge> challenges = userChallengeMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .eq("challenge_date", today));

        for (UserChallenge uc : challenges) {
            if (uc.getCompleted()) continue;

            DailyChallengeDef def = challengeDefMapper.selectOneById(uc.getChallengeDefId());
            if (def == null) continue;

            int progress = uc.getProgress();
            boolean completed = false;

            switch (def.getChallengeType()) {
                case "STUDY_SESSION":
                    progress += 1;
                    completed = progress >= def.getTargetValue();
                    break;
                case "ACCURACY":
                    if (accuracy * 100 >= def.getTargetValue()) {
                        progress = def.getTargetValue();
                        completed = true;
                    }
                    break;
                case "ENERGY_EARN": {
                    // Sum energyEarned from today's completed sessions
                    Long totalEarned = studySessionMapper.selectOneByQueryAs(
                            QueryWrapper.create()
                                    .select("COALESCE(SUM(energy_earned), 0)")
                                    .eq("user_id", userId)
                                    .eq("status", "COMPLETED")
                                    .ge("completed_at", today.atStartOfDay()),
                            Long.class);
                    progress = totalEarned != null ? totalEarned.intValue() : 0;
                    completed = progress >= def.getTargetValue();
                    break;
                }
                case "PERFECT_SESSION":
                    if (accuracy == 1.0) {
                        progress = 1;
                        completed = true;
                    }
                    break;
            }

            uc.setProgress(progress);
            uc.setCompleted(completed);
            userChallengeMapper.update(uc);
        }
    }

    @Transactional
    public void claimReward(Long userId, Long userChallengeId) {
        UserChallenge uc = userChallengeMapper.selectOneById(userChallengeId);
        if (uc == null || !uc.getUserId().equals(userId)) {
            throw new BusinessException("挑战记录不存在");
        }
        if (!uc.getCompleted()) {
            throw new BusinessException("挑战尚未完成");
        }
        if (uc.getRewardClaimed()) {
            throw new BusinessException("奖励已领取");
        }

        DailyChallengeDef def = challengeDefMapper.selectOneById(uc.getChallengeDefId());
        if (def == null) throw new BusinessException("挑战定义不存在");

        if (def.getRewardEnergy() > 0) {
            energyService.earnEnergy(userId, def.getRewardEnergy(), "daily_challenge",
                    "daily_challenge_def", def.getId());
        }

        uc.setRewardClaimed(true);
        userChallengeMapper.update(uc);
    }
}
