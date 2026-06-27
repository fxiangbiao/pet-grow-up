import { getChapters } from '$lib/api/story';
import type { ChapterDTO } from '$lib/types/api';

let chapters = $state<ChapterDTO[]>([]);
let loading = $state(false);

export const storyStore = {
  get chapters() { return chapters; },
  get loading() { return loading; },

  get unlockedCount() {
    return chapters.filter(c => c.unlocked).length;
  },

  get completedCount() {
    return chapters.filter(c => c.completed).length;
  },

  get latestUnlocked() {
    return chapters.filter(c => c.unlocked && !c.completed).sort((a, b) => a.chapterNumber - b.chapterNumber)[0] || null;
  },

  async refresh() {
    loading = true;
    try {
      chapters = await getChapters();
    } catch {}
    loading = false;
  },
};
