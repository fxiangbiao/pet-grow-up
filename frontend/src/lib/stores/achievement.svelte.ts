import { getAchievements, markNotified } from '$lib/api/achievement';
import type { AchievementProgress, AchievementUnlockEvent } from '$lib/types/api';

let progress = $state<AchievementProgress | null>(null);
let pendingUnlock = $state<AchievementUnlockEvent | null>(null);
let loading = $state(false);
let loadError = $state('');

export const achievementStore = {
  get progress() { return progress; },
  get pendingUnlock() { return pendingUnlock; },
  get loading() { return loading; },
  get loadError() { return loadError; },
  get unlockedCount() { return progress?.unlockedCount ?? 0; },
  get totalCount() { return progress?.totalCount ?? 0; },

  async refresh() {
    loading = true;
    loadError = '';
    try {
      progress = await getAchievements();
    } catch {
      loadError = '无法加载成就数据，请检查网络或重新登录';
    } finally {
      loading = false;
    }
  },

  setPendingUnlock(event: AchievementUnlockEvent | null) {
    pendingUnlock = event;
  },

  async markNotified(id: number) {
    try {
      await markNotified(id);
    } catch {
      // silently fail
    }
  }
};
