import { getSpirits, getSpiritStatus } from '$lib/api/spirit';
import type { SpiritDTO, SpiritStatus } from '$lib/types/api';

let spirits = $state<SpiritDTO[]>([]);
let activeSpirit = $derived(spirits.find(s => s.isActive) ?? null);

// ── Sprint C: Dormancy & interaction tracking ──
let dormancyLevel = $state(0);
let lastStudyDate = $state<string | null>(null);
let daysSinceLastStudy = $state(0);
let personalityType = $state('cheerful');
let lastInteractionTime = $state<number>(Date.now());
let statusLoaded = $state(false);
let showGreeting = $state(false);

function loadFromLocalStorage() {
  try {
    const stored = localStorage.getItem('spirit_last_interaction');
    if (stored) lastInteractionTime = parseInt(stored, 10);
    const storedDate = localStorage.getItem('spirit_last_study_date');
    if (storedDate) lastStudyDate = storedDate;
  } catch { /* ignore */ }
}

function saveToLocalStorage() {
  try {
    localStorage.setItem('spirit_last_interaction', String(lastInteractionTime));
    if (lastStudyDate) localStorage.setItem('spirit_last_study_date', lastStudyDate);
  } catch { /* ignore */ }
}

export const spiritStore = {
  get spirits() { return spirits; },
  get activeSpirit() { return activeSpirit; },
  get dormancyLevel() { return dormancyLevel; },
  get lastStudyDate() { return lastStudyDate; },
  get daysSinceLastStudy() { return daysSinceLastStudy; },
  get personalityType() { return personalityType; },
  get lastInteractionTime() { return lastInteractionTime; },
  get statusLoaded() { return statusLoaded; },
  get showGreeting() { return showGreeting; },

  async refresh(userId: number) {
    try {
      spirits = await getSpirits();
    } catch {
      // silently fail
    }
  },

  setSpirits(list: SpiritDTO[]) {
    spirits = list;
  },

  /** Call on app startup — checks dormancy and decides whether to show greeting */
  async checkStatus() {
    loadFromLocalStorage();
    try {
      const status: SpiritStatus = await getSpiritStatus();
      dormancyLevel = status.dormancyLevel;
      lastStudyDate = status.lastStudyDate;
      daysSinceLastStudy = status.daysSinceLastStudy;
      personalityType = status.personalityType || 'cheerful';

      // Save for offline fallback
      if (lastStudyDate) {
        localStorage.setItem('spirit_last_study_date', lastStudyDate);
      }
    } catch {
      // Offline: use localStorage fallback
      if (lastStudyDate) {
        const last = new Date(lastStudyDate);
        const now = new Date();
        const diffDays = Math.floor((now.getTime() - last.getTime()) / (1000 * 60 * 60 * 24));
        daysSinceLastStudy = diffDays;
        dormancyLevel = diffDays >= 3 ? 2 : diffDays >= 1 ? 1 : 0;
      }
    }

    // Decide whether to show greeting (>30 min since last interaction)
    const minutesSince = (Date.now() - lastInteractionTime) / (1000 * 60);
    showGreeting = minutesSince > 30;

    statusLoaded = true;
    saveToLocalStorage();
  },

  /** Record a learning interaction (resets dormancy) */
  recordInteraction() {
    lastInteractionTime = Date.now();
    lastStudyDate = new Date().toISOString().split('T')[0];
    daysSinceLastStudy = 0;
    dormancyLevel = 0;
    showGreeting = false;
    saveToLocalStorage();
  },

  /** Dismiss greeting without recording interaction */
  dismissGreeting() {
    showGreeting = false;
    lastInteractionTime = Date.now();
    saveToLocalStorage();
  },

  /** Wake up from dormancy — called after completing a study session */
  wakeUp() {
    dormancyLevel = 0;
    daysSinceLastStudy = 0;
    lastStudyDate = new Date().toISOString().split('T')[0];
    saveToLocalStorage();
  }
};
