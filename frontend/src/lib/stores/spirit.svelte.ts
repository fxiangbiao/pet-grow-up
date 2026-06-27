import { getSpirits } from '$lib/api/spirit';
import type { SpiritDTO } from '$lib/types/api';

let spirits = $state<SpiritDTO[]>([]);
let activeSpirit = $derived(spirits.find(s => s.isActive) ?? null);

export const spiritStore = {
  get spirits() { return spirits; },
  get activeSpirit() { return activeSpirit; },

  async refresh(userId: number) {
    try {
      spirits = await getSpirits();
    } catch {
      // silently fail
    }
  },

  setSpirits(list: SpiritDTO[]) {
    spirits = list;
  }
};
