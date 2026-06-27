import { api } from './client';
import type { AchievementProgress } from '$lib/types/api';

export function getAchievements(): Promise<AchievementProgress> {
  return api.get<AchievementProgress>('/achievements');
}

export function markNotified(userAchievementId: number): Promise<null> {
  return api.post<null>(`/achievements/${userAchievementId}/notified`);
}
