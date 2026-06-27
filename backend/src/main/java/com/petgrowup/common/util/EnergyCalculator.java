package com.petgrowup.common.util;

public class EnergyCalculator {

    private EnergyCalculator() {}

    /**
     * Calculate final energy reward for a study session.
     * Implements the formula from the design document:
     *
     * baseEnergy = baseReward × completionCoefficient
     * qualityMultiplier = accuracyFactor × timeFactor × streakFactor
     * finalEnergy = baseEnergy × qualityMultiplier × difficultyCoefficient × subjectCoefficient
     */
    public static long calculateFinalEnergy(
            long baseReward,
            double accuracy,
            long actualDurationSeconds,
            long expectedDurationSeconds,
            int consecutiveDays,
            double difficultyCoefficient,
            double subjectCoefficient) {

        // Completion status coefficient
        double completionCoeff;
        if (accuracy >= 0.95) {
            completionCoeff = 2.0;
        } else if (accuracy >= 0.80) {
            completionCoeff = 1.5;
        } else if (accuracy >= 0.60) {
            completionCoeff = 1.0;
        } else {
            completionCoeff = 0.5;
        }

        double baseEnergy = baseReward * completionCoeff;

        // Quality multiplier
        double accuracyFactor = Math.max(accuracy, 0.0);
        double timeFactor = Math.min((double) actualDurationSeconds / Math.max(expectedDurationSeconds, 1), 1.5);
        double streakFactor = Math.min(1.0 + (consecutiveDays * 0.1), 2.0);
        double qualityMultiplier = accuracyFactor * timeFactor * streakFactor;

        return Math.round(baseEnergy * qualityMultiplier * difficultyCoefficient * subjectCoefficient);
    }
}
