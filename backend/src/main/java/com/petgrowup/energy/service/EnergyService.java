package com.petgrowup.energy.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.petgrowup.auth.entity.User;
import com.petgrowup.auth.mapper.UserMapper;
import com.petgrowup.common.exception.BusinessException;
import com.petgrowup.energy.dto.EnergyBalanceDTO;
import com.petgrowup.energy.dto.EnergyTransactionDTO;
import com.petgrowup.energy.entity.EnergyTransaction;
import com.petgrowup.energy.mapper.EnergyTransactionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class EnergyService {

    private final EnergyTransactionMapper transactionMapper;
    private final UserMapper userMapper;

    public EnergyService(EnergyTransactionMapper transactionMapper, UserMapper userMapper) {
        this.transactionMapper = transactionMapper;
        this.userMapper = userMapper;
    }

    @Transactional
    public EnergyTransaction earnEnergy(Long userId, long amount, String source, String referenceType, Long referenceId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        user.setCurrentEnergy(user.getCurrentEnergy() + amount);
        user.setTotalEnergy(user.getTotalEnergy() + amount);
        userMapper.update(user);

        EnergyTransaction tx = EnergyTransaction.builder()
                .userId(userId)
                .amount(amount)
                .transactionType("EARN")
                .source(source)
                .referenceType(referenceType)
                .referenceId(referenceId)
                .balanceAfter(user.getCurrentEnergy())
                .build();

        transactionMapper.insert(tx);
        return tx;
    }

    @Transactional
    public EnergyTransaction spendEnergy(Long userId, long amount, String source) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");
        if (user.getCurrentEnergy() < amount) throw new BusinessException("能量不足");

        user.setCurrentEnergy(user.getCurrentEnergy() - amount);
        userMapper.update(user);

        EnergyTransaction tx = EnergyTransaction.builder()
                .userId(userId)
                .amount(-amount)
                .transactionType("SPEND")
                .source(source)
                .balanceAfter(user.getCurrentEnergy())
                .build();

        transactionMapper.insert(tx);
        return tx;
    }

    public EnergyBalanceDTO getBalance(Long userId) {
        User user = userMapper.selectOneById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();

        Long todayEarned = transactionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(SUM(amount), 0)")
                        .eq("user_id", userId)
                        .eq("transaction_type", "EARN")
                        .ge("created_at", todayStart),
                Long.class
        );
        if (todayEarned == null) todayEarned = 0L;

        Long todaySpentRaw = transactionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(SUM(ABS(amount)), 0)")
                        .eq("user_id", userId)
                        .eq("transaction_type", "SPEND")
                        .ge("created_at", todayStart),
                Long.class
        );
        if (todaySpentRaw == null) todaySpentRaw = 0L;

        LocalDateTime weekStart = todayStart.minusDays(today.getDayOfWeek().getValue() - 1);
        Long weeklyTotal = transactionMapper.selectOneByQueryAs(
                QueryWrapper.create()
                        .select("COALESCE(SUM(amount), 0)")
                        .eq("user_id", userId)
                        .eq("transaction_type", "EARN")
                        .ge("created_at", weekStart),
                Long.class
        );
        if (weeklyTotal == null) weeklyTotal = 0L;

        return EnergyBalanceDTO.builder()
                .currentBalance(user.getCurrentEnergy())
                .todayEarned(todayEarned)
                .todaySpent(todaySpentRaw)
                .weeklyTotal(weeklyTotal)
                .build();
    }

    public List<EnergyTransactionDTO> getTransactions(Long userId, int page, int size) {
        int offset = page * size;
        List<EnergyTransaction> txs = transactionMapper.selectListByQuery(
                QueryWrapper.create()
                        .eq("user_id", userId)
                        .orderBy("created_at", false)
                        .limit(size)
                        .offset(offset)
        );
        return txs.stream().map(tx -> EnergyTransactionDTO.builder()
                .id(tx.getId())
                .amount(tx.getAmount())
                .transactionType(tx.getTransactionType())
                .source(tx.getSource())
                .balanceAfter(tx.getBalanceAfter())
                .createdAt(tx.getCreatedAt())
                .build()).collect(Collectors.toList());
    }
}
