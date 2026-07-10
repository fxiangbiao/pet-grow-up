// frontend/src/lib/room/themes/types.ts

export interface RoomTheme {
  key: string;
  name: string;
  icon: string;
  description: string;
  wall: {
    gradient: [string, string];
    pattern: 'stars' | 'leaves' | 'bamboo' | 'crystal' | 'waves' | 'none';
  };
  floor: {
    color: string;
    plankColor: string;
    baseboardColor: string;
  };
  window: {
    frameColor: string;
    glassColor: string;
    curtainColor: string;
    style: 'arched' | 'round' | 'square' | 'porthole';
  };
  lamp: {
    glowColor: string;
    bodyColor: string;
    style: 'pendant' | 'lantern' | 'crystal' | 'mushroom' | 'shell';
  };
  defaultRug: {
    color: string;
    opacity: number;
  };
  ambientParticles: 'stars' | 'fireflies' | 'petals' | 'sparkles' | 'bubbles' | 'none';
  colorScheme: {
    primary: string;
    secondary: string;
    accent: string;
  };
}
