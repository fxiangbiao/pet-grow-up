import { api } from './client';
import type { ItemDef, UserItem, UseItemResult } from '$lib/types/api';

export function getShopItems(category?: string): Promise<ItemDef[]> {
  const params = category ? `?category=${category}` : '';
  return api.get<ItemDef[]>(`/shop/items${params}`);
}

export function buyItem(itemDefId: number, quantity: number = 1): Promise<null> {
  return api.post<null>('/shop/buy', { itemDefId, quantity });
}

export function getInventory(): Promise<UserItem[]> {
  return api.get<UserItem[]>('/inventory');
}

export function useItem(userItemId: number, spiritId: number, quantity: number = 1): Promise<UseItemResult> {
  return api.post<UseItemResult>('/inventory/use', { userItemId, spiritId, quantity });
}

// ── Sprint E: Gacha ──
export interface GachaResult {
  itemKey: string;
  name: string;
  iconUrl: string;
  rarity: 'common' | 'rare' | 'epic';
  isNew: boolean;
  refundEnergy: number;
}

export function drawGacha(free: boolean = false): Promise<GachaResult> {
  return api.post<GachaResult>('/shop/gacha/draw', { free });
}
