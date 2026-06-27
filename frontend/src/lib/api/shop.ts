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
