import type { RoomTheme } from './types';

export const oceanDeep: RoomTheme = {
  key: 'ocean_deep',
  name: '深海小屋',
  icon: '🌊',
  description: '蔚蓝深海中的静谧小屋',
  wall: { gradient: ['#e0f2fe', '#bae6fd'], pattern: 'waves' },
  floor: { color: '#94a3b8', plankColor: '#64748b', baseboardColor: '#475569' },
  window: { frameColor: '#0284c7', glassColor: '#0c4a6e', curtainColor: '#7dd3fc', style: 'porthole' },
  lamp: { glowColor: '#dbeafe', bodyColor: '#f59e0b', style: 'shell' },
  defaultRug: { color: '#67e8f9', opacity: 0.3 },
  ambientParticles: 'bubbles',
  colorScheme: { primary: '#0284c7', secondary: '#38bdf8', accent: '#fbbf24' },
};
