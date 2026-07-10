import type { RoomTheme } from './types';

export const ancientStudy: RoomTheme = {
  key: 'ancient_study',
  name: '古风书房',
  icon: '📜',
  description: '笔墨纸砚，书香四溢',
  wall: { gradient: ['#fefce8', '#fef9c3'], pattern: 'bamboo' },
  floor: { color: '#a16207', plankColor: '#854d0e', baseboardColor: '#713f12' },
  window: { frameColor: '#713f12', glassColor: '#fef9c3', curtainColor: '#fdba74', style: 'square' },
  lamp: { glowColor: '#fef3c7', bodyColor: '#dc2626', style: 'lantern' },
  defaultRug: { color: '#fdba74', opacity: 0.3 },
  ambientParticles: 'petals',
  colorScheme: { primary: '#b45309', secondary: '#d97706', accent: '#dc2626' },
};
