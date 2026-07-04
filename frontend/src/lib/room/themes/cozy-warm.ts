import type { RoomTheme } from './types';

export const cozyWarm: RoomTheme = {
  key: 'cozy_warm',
  name: '温馨暖居',
  icon: '🏠',
  description: '温暖舒适的默认小屋',
  wall: { gradient: ['#fef9ef', '#fef3c7'], pattern: 'none' },
  floor: { color: '#d4a574', plankColor: '#c49564', baseboardColor: '#8B7355' },
  window: { frameColor: '#8B7355', glassColor: '#87CEEB', curtainColor: '#ffb3ba', style: 'arched' },
  lamp: { glowColor: '#fff8e1', bodyColor: '#f9a825', style: 'pendant' },
  defaultRug: { color: '#f8bbd0', opacity: 0.4 },
  ambientParticles: 'none',
  colorScheme: { primary: '#f59e0b', secondary: '#d4a574', accent: '#fbbf24' },
};
