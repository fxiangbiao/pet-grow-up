import type { RoomTheme } from './types';

export const forestGreen: RoomTheme = {
  key: 'forest_green',
  name: '翠林幽居',
  icon: '🌿',
  description: '绿意盎然的森林小屋',
  wall: { gradient: ['#ecfdf5', '#d1fae5'], pattern: 'leaves' },
  floor: { color: '#78716c', plankColor: '#57534e', baseboardColor: '#44403c' },
  window: { frameColor: '#57534e', glassColor: '#a7f3d0', curtainColor: '#86efac', style: 'round' },
  lamp: { glowColor: '#fef9c3', bodyColor: '#eab308', style: 'mushroom' },
  defaultRug: { color: '#6ee7b7', opacity: 0.35 },
  ambientParticles: 'fireflies',
  colorScheme: { primary: '#22c55e', secondary: '#78716c', accent: '#fbbf24' },
};
