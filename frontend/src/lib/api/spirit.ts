import { api } from './client';
import type { SpiritDTO, SpiritSpecies, SpiritStatus, WeaknessDTO } from '$lib/types/api';

export function getSpecies(): Promise<SpiritSpecies[]> {
  return api.get<SpiritSpecies[]>('/spirits/species');
}

export function getSpirits(): Promise<SpiritDTO[]> {
  return api.get<SpiritDTO[]>('/spirits');
}

export function getSpiritDetail(id: number): Promise<SpiritDTO> {
  return api.get<SpiritDTO>(`/spirits/${id}`);
}

export function getSpiritStatus(): Promise<SpiritStatus> {
  return api.get<SpiritStatus>('/spirits/status');
}

export function chooseStarter(speciesId: number, personalityType: string, nickname: string): Promise<SpiritDTO> {
  return api.post<SpiritDTO>('/spirits/choose', { speciesId, personalityType, nickname });
}

export function feedSpirit(id: number, energyAmount: number): Promise<SpiritDTO> {
  return api.post<SpiritDTO>(`/spirits/${id}/feed`, { energyAmount });
}

export function evolveSpirit(id: number): Promise<SpiritDTO> {
  return api.post<SpiritDTO>(`/spirits/${id}/evolve`);
}

export function activateSpirit(id: number): Promise<SpiritDTO> {
  return api.put<SpiritDTO>(`/spirits/${id}/activate`);
}

// ── Sprint E: Accessories ──
export interface AccessoryDTO {
  slot: string;
  itemKey: string;
  name: string;
  iconUrl: string;
  rarity: string;
}

export function getEquippedAccessories(spiritId: number): Promise<AccessoryDTO[]> {
  return api.get<AccessoryDTO[]>(`/spirits/${spiritId}/accessories`);
}

export function equipAccessory(spiritId: number, slot: string, itemDefId: number): Promise<AccessoryDTO[]> {
  return api.put<AccessoryDTO[]>(`/spirits/${spiritId}/accessories`, { slot, itemDefId });
}

export function unequipAccessory(spiritId: number, slot: string): Promise<AccessoryDTO[]> {
  return api.put<AccessoryDTO[]>(`/spirits/${spiritId}/accessories`, { slot });
}

export function getWeaknesses(limit = 10): Promise<WeaknessDTO[]> {
  return api.get<WeaknessDTO[]>(`/study/weaknesses?limit=${limit}`);
}
