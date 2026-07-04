import type { RoomTheme } from './types';

export const starryNight: RoomTheme = {
  key: 'starry_night',
  name: '星空夜语',
  icon: '🌌',
  description: '深蓝夜空下繁星点点',
  wall: { gradient: ['#1e1b4b', '#312e81'], pattern: 'stars' },
  floor: { color: '#334155', plankColor: '#1e293b', baseboardColor: '#475569' },
  window: { frameColor: '#6366f1', glassColor: '#0f172a', curtainColor: '#818cf8', style: 'arched' },
  lamp: { glowColor: '#e0e7ff', bodyColor: '#c7d2fe', style: 'pendant' },
  defaultRug: { color: '#6366f1', opacity: 0.3 },
  ambientParticles: 'stars',
  colorScheme: { primary: '#6366f1', secondary: '#818cf8', accent: '#fbbf24' },
};
