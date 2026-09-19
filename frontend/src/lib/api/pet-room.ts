// frontend/src/lib/api/pet-room.ts
import { api } from './client';
import type { SpiritDTO } from '$lib/types/api';

export interface PlacedItem {
  itemDefId: number;
  userItemId?: number;
  itemKey: string;
  name: string;
  iconUrl: string;
  category: string;
  x: number;
  y: number;
}

export interface PetRoomData {
  id: number;
  roomStyle: string;
  themeName: string;
  themeIcon: string;
  furniture: PlacedItem[];
  activeSpirit: SpiritDTO | null;
}

export function getPetRoom(): Promise<PetRoomData> {
  return api.get<PetRoomData>('/pet-room');
}

export function placeItem(userItemId: number, x: number, y: number): Promise<PetRoomData> {
  return api.post<PetRoomData>('/pet-room/place', { userItemId, x, y });
}

/**
 * 移除屋内装饰。
 * userItemId 可能为空（历史数据里早期写入的槽位没有它），此时用 itemDefId 兜底——
 * 以前这里在 userItemId 为空时把 itemDefId 当 userItemId 发过去，后端匹配不到却返回 200，
 * 于是"装饰删不掉但提示已移除"。
 */
export function removeItem(userItemId?: number | null, itemDefId?: number | null): Promise<PetRoomData> {
  const p = new URLSearchParams();
  if (userItemId != null) p.set('userItemId', String(userItemId));
  if (itemDefId != null) p.set('itemDefId', String(itemDefId));
  return api.delete<PetRoomData>(`/pet-room/remove?${p.toString()}`);
}

/**
 * 更新装饰位置。
 * userItemId 为空（历史数据）时传 itemDefId 兜底，后端据此定位槽位。
 */
export function updatePosition(userItemId: number | null, x: number, y: number, itemDefId?: number | null): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/position', { userItemId, itemDefId: itemDefId ?? null, x, y });
}

export function changeTheme(themeKey: string): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/theme', { themeKey });
}

export function getAvailableDecorations(): Promise<PlacedItem[]> {
  return api.get<PlacedItem[]>('/pet-room/available-decorations');
}
