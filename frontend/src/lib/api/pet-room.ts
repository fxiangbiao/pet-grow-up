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

export function removeItem(userItemId: number): Promise<PetRoomData> {
  return api.delete<PetRoomData>(`/pet-room/remove?userItemId=${userItemId}`);
}

export function updatePosition(userItemId: number, x: number, y: number): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/position', { userItemId, x, y });
}

export function changeTheme(themeKey: string): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/theme', { themeKey });
}

export function getAvailableDecorations(): Promise<PlacedItem[]> {
  return api.get<PlacedItem[]>('/pet-room/available-decorations');
}
