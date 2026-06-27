import { api } from './client';
import type { DailyChallenge } from '$lib/types/api';

export function getTodayChallenges(): Promise<DailyChallenge[]> {
  return api.get<DailyChallenge[]>('/challenges/today');
}

export function claimReward(userChallengeId: number): Promise<null> {
  return api.post<null>(`/challenges/${userChallengeId}/claim`);
}
