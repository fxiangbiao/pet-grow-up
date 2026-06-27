import { getBalance, type EnergyBalance } from '$lib/api/energy';

let balance = $state<EnergyBalance | null>(null);

export const energyStore = {
  get balance() { return balance; },

  async refresh(userId: number) {
    try {
      balance = await getBalance();
    } catch {
      // silently fail, will retry
    }
  }
};
