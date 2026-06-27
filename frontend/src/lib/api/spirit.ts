import { api } from './client';
import type { SpiritDTO, SpiritSpecies } from '$lib/types/api';

export function getSpecies(): Promise<SpiritSpecies[]> {
  return api.get<SpiritSpecies[]>('/spirits/species');
}

export function getSpirits(): Promise<SpiritDTO[]> {
  return api.get<SpiritDTO[]>('/spirits');
}

export function getSpiritDetail(id: number): Promise<SpiritDTO> {
  return api.get<SpiritDTO>(`/spirits/${id}`);
}

export function chooseStarter(speciesId: number, nickname: string): Promise<SpiritDTO> {
  return api.post<SpiritDTO>('/spirits/choose', { speciesId, nickname });
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
