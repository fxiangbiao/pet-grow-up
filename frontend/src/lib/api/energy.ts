import { api } from './client';

export interface EnergyBalance {
  currentBalance: number;
  todayEarned: number;
  todaySpent: number;
  weeklyTotal: number;
}

export interface EnergyTransaction {
  id: number;
  amount: number;
  transactionType: string;
  source: string;
  balanceAfter: number;
  createdAt: string;
}

export function getBalance(): Promise<EnergyBalance> {
  return api.get<EnergyBalance>('/energy/balance');
}

export function getTransactions(page = 0, size = 20): Promise<EnergyTransaction[]> {
  return api.get<EnergyTransaction[]>(`/energy/transactions?page=${page}&size=${size}`);
}
