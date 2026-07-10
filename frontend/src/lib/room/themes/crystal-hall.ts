import type { RoomTheme } from './types';

export const crystalHall: RoomTheme = {
  key: 'crystal_hall',
  name: '水晶殿堂',
  icon: '💎',
  description: '晶莹剔透的梦幻宫殿',
  wall: { gradient: ['#faf5ff', '#f3e8ff'], pattern: 'crystal' },
  floor: { color: '#c4b5fd', plankColor: '#a78bfa', baseboardColor: '#8b5cf6' },
  window: { frameColor: '#7c3aed', glassColor: '#e0e7ff', curtainColor: '#c4b5fd', style: 'arched' },
  lamp: { glowColor: '#f3e8ff', bodyColor: '#a78bfa', style: 'crystal' },
  defaultRug: { color: '#c4b5fd', opacity: 0.4 },
  ambientParticles: 'sparkles',
  colorScheme: { primary: '#8b5cf6', secondary: '#a78bfa', accent: '#fbbf24' },
};
