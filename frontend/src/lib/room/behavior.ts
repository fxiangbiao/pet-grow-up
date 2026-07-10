// frontend/src/lib/room/behavior.ts
// Spirit autonomous behavior state machine for pet room

import type { PlacedItem } from '$lib/api/pet-room';

export type BehaviorState =
  | 'idle_stand'
  | 'wander_left'
  | 'wander_right'
  | 'wander_center'
  | 'sit_on_bed'
  | 'sit_on_sofa'
  | 'read_at_bookshelf'
  | 'play_with_ball'
  | 'look_at_plant'
  | 'sleep';

export interface BehaviorFrame {
  state: BehaviorState;
  position: { left: string; bottom: string }; // CSS percentages
  mood: 'idle' | 'happy' | 'excited' | 'sleeping' | 'thinking';
  label: string;       // emoji indicator
}

const BEHAVIOR_DEFS: Record<BehaviorState, {
  position: { left: string; bottom: string };
  mood: 'idle' | 'happy' | 'excited' | 'sleeping' | 'thinking';
  label: string;
  duration: [number, number]; // [min, max] seconds
  requires?: string;          // furniture itemKey
  priority: number;           // higher = more likely
}> = {
  idle_stand:        { position: { left: '50%', bottom: '22%' }, mood: 'idle',     label: '',      duration: [5, 15],  priority: 10 },
  wander_left:       { position: { left: '30%', bottom: '24%' }, mood: 'idle',     label: '🚶',   duration: [4, 8],   priority: 6 },
  wander_right:      { position: { left: '70%', bottom: '24%' }, mood: 'idle',     label: '🚶',   duration: [4, 8],   priority: 6 },
  wander_center:     { position: { left: '50%', bottom: '22%' }, mood: 'happy',    label: '',      duration: [3, 6],   priority: 5 },
  sit_on_bed:        { position: { left: '22%', bottom: '18%' }, mood: 'sleeping', label: '😴',   duration: [10, 25], priority: 4, requires: 'deco_bed_small' },
  sit_on_sofa:       { position: { left: '72%', bottom: '18%' }, mood: 'happy',    label: '🛋️',   duration: [8, 18],  priority: 4, requires: 'deco_sofa' },
  read_at_bookshelf: { position: { left: '78%', bottom: '24%' }, mood: 'thinking', label: '📖',   duration: [10, 20], priority: 4, requires: 'deco_bookshelf' },
  play_with_ball:    { position: { left: '55%', bottom: '26%' }, mood: 'excited',  label: '⚽',   duration: [5, 10],  priority: 3, requires: 'deco_toy_ball' },
  look_at_plant:     { position: { left: '40%', bottom: '24%' }, mood: 'thinking', label: '🌱',   duration: [6, 12],  priority: 3, requires: 'deco_plant' },
  sleep:             { position: { left: '50%', bottom: '20%' }, mood: 'sleeping', label: '💤',   duration: [15, 40], priority: 2 },
};

export function getBehaviorFrame(state: BehaviorState): BehaviorFrame {
  const def = BEHAVIOR_DEFS[state];
  return {
    state,
    position: def.position,
    mood: def.mood,
    label: def.label,
  };
}

export function pickNextState(
  current: BehaviorState,
  furniture: PlacedItem[],
  happiness: number,
): BehaviorState {
  // Build eligible states: exclude current, filter by furniture requirements
  const furnitureKeys = new Set(furniture.map(f => f.itemKey));

  const eligible = Object.entries(BEHAVIOR_DEFS)
    .filter(([key, def]) => {
      if (key === current) return false;                    // don't repeat same state
      if (def.requires && !furnitureKeys.has(def.requires)) return false; // missing furniture
      return true;
    })
    .map(([key, def]) => ({ key: key as BehaviorState, def }));

  if (eligible.length === 0) {
    // Fallback to wander states
    const wanderStates: BehaviorState[] = ['wander_left', 'wander_right', 'wander_center', 'idle_stand'];
    return wanderStates[Math.floor(Math.random() * wanderStates.length)];
  }

  // Weight by priority + slight happiness boost for happy/excited states
  const totalWeight = eligible.reduce((sum, e) => {
    let w = e.def.priority;
    if (happiness >= 80 && (e.def.mood === 'excited' || e.def.mood === 'happy')) w += 3;
    if (happiness < 30 && e.def.mood === 'sleeping') w += 2;
    return sum + Math.max(w, 1);
  }, 0);

  let roll = Math.random() * totalWeight;
  for (const e of eligible) {
    let w = e.def.priority;
    if (happiness >= 80 && (e.def.mood === 'excited' || e.def.mood === 'happy')) w += 3;
    if (happiness < 30 && e.def.mood === 'sleeping') w += 2;
    roll -= Math.max(w, 1);
    if (roll <= 0) return e.key;
  }

  return eligible[eligible.length - 1].key;
}

export function getStateDuration(state: BehaviorState): number {
  const def = BEHAVIOR_DEFS[state];
  if (!def) return 8000;
  const [min, max] = def.duration;
  return (min + Math.random() * (max - min)) * 1000;
}
