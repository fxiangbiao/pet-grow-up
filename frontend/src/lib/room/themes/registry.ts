// frontend/src/lib/room/themes/registry.ts
import type { RoomTheme } from './types';
import { cozyWarm } from './cozy-warm';
import { starryNight } from './starry-night';
import { forestGreen } from './forest-green';
import { ancientStudy } from './ancient-study';
import { crystalHall } from './crystal-hall';
import { oceanDeep } from './ocean-deep';

export const themeRegistry: Map<string, RoomTheme> = new Map([
  ['cozy_warm', cozyWarm],
  ['starry_night', starryNight],
  ['forest_green', forestGreen],
  ['ancient_study', ancientStudy],
  ['crystal_hall', crystalHall],
  ['ocean_deep', oceanDeep],
]);

export const defaultTheme = cozyWarm;

export function getTheme(key: string): RoomTheme {
  return themeRegistry.get(key) || defaultTheme;
}

export function getAllThemes(): RoomTheme[] {
  return Array.from(themeRegistry.values());
}
