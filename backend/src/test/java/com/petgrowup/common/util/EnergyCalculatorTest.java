package com.petgrowup.common.util;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.*;

class EnergyCalculatorTest {

    @ParameterizedTest
    @CsvSource({
        "100, 1.0, 120, 120, 1, 1.0, 1.0, 220",
        "100, 0.5, 120, 120, 1, 1.0, 1.0, 28",
        "100, 0.0, 120, 120, 1, 1.0, 1.0, 0",
        "100, 0.95, 120, 120, 1, 1.0, 1.0, 209",
        "100, 0.80, 120, 120, 1, 1.0, 1.0, 132",
        "100, 0.60, 120, 120, 1, 1.0, 1.0, 66",
        "100, 1.0, 180, 120, 1, 1.0, 1.0, 330",
        "100, 1.0, 60, 120, 1, 1.0, 1.0, 110",
        "100, 1.0, 120, 120, 5, 1.0, 1.0, 300",
        "100, 1.0, 120, 120, 10, 1.0, 1.0, 400",
        "100, 1.0, 120, 120, 1, 2.0, 1.0, 440",
        "100, 1.0, 120, 120, 1, 1.0, 1.5, 330",
    })
    void calculateFinalEnergy(long baseReward, double accuracy, long actualDuration,
                              long expectedDuration, int consecutiveDays,
                              double difficultyCoeff, double subjectCoeff, long expected) {
        long result = EnergyCalculator.calculateFinalEnergy(
                baseReward, accuracy, actualDuration, expectedDuration,
                consecutiveDays, difficultyCoeff, subjectCoeff);
        assertEquals(expected, result);
    }

    @Test
    void minimumEnergyForZeroAccuracy() {
        long result = EnergyCalculator.calculateFinalEnergy(100, 0, 120, 120, 1, 1.0, 1.0);
        assertTrue(result >= 0);
    }

    @Test
    void timeFactorIsCappedAtMax() {
        long normal = EnergyCalculator.calculateFinalEnergy(100, 1.0, 120, 120, 1, 1.0, 1.0); // time=1.0
        long slow = EnergyCalculator.calculateFinalEnergy(100, 1.0, 1000, 120, 1, 1.0, 1.0);  // time capped at 1.5
        assertTrue(slow > normal);
        // Verify extreme time doesn't exceed cap
        long extreme = EnergyCalculator.calculateFinalEnergy(100, 1.0, 99999, 120, 1, 1.0, 1.0);
        assertEquals(slow, extreme);
    }

    @Test
    void streakFactorIsCappedAtMax() {
        long streak10 = EnergyCalculator.calculateFinalEnergy(100, 1.0, 120, 120, 10, 1.0, 1.0); // streak=2.0 (capped)
        long streak20 = EnergyCalculator.calculateFinalEnergy(100, 1.0, 120, 120, 20, 1.0, 1.0); // streak=2.0 (capped)
        assertEquals(streak10, streak20);
    }
}
