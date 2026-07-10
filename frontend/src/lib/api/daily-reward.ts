import { api } from './client';

export interface DailyRewardDTO {
  id: number;
  rewardKey: string;
  name: string;
  description: string;
  rewardType: string;
  rewardValue: number;
  rewardItemKey: string | null;
  rewardItemName: string | null;
  iconUrl: string;
  unlockDay: number;
  isMilestone: boolean;
  claimed: boolean;
}

export interface DailyRewardStatus {
  eligible: boolean;
  claimedToday: boolean;
  consecutiveLoginDays: number;
  todayReward: DailyRewardDTO | null;
  recentRewards: DailyRewardDTO[];
  upcomingMilestones: DailyRewardDTO[];
}

export interface ClaimResult {
  rewardType: string;
  energyEarned: number;
  itemName: string;
  itemIcon: string;
  consecutiveLoginDays: number;
  isMilestone: boolean;
  milestoneName: string;
}

export function getDailyRewardStatus(): Promise<DailyRewardStatus> {
  return api.get<DailyRewardStatus>('/daily-reward/status');
}

export function claimDailyReward(): Promise<ClaimResult> {
  return api.post<ClaimResult>('/daily-reward/claim');
}
