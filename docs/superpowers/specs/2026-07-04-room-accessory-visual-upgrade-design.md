# Room & Accessory Visual Upgrade — Design Spec

**Date:** 2026-07-04
**Status:** Approved — Layer 1 implementation in progress

## Overview

Upgrade pet room decoration and spirit accessory rendering from emoji-based to hand-drawn SVG with image fallback support. Three layers delivered incrementally.

## Layer 1: Rendering Engine

**Goal:** Everything looks beautiful. Emoji → hand-drawn SVG. Theme system. Proper layering.

### 1.1 Spirit Accessory Rendering

Replace `SpiritAvatar.svelte` lines 517-530 (emoji `<span>` with crude CSS `%` positioning).

New structure:
```
frontend/src/lib/accessories/
├── registry.ts           # itemKey → AccessoryRenderer
├── renderers/
│   ├── head.ts           # Hats: red cap, bow, flower crown, graduation cap
│   ├── neck.ts           # Scarves/necklaces: blue scarf, bowtie, star necklace, perseverance scarf
│   ├── eyes.ts           # Glasses: round glasses, star shades
│   └── effects.ts        # Particle effects: gold sparkle, rainbow aura
└── types.ts              # RenderContext, AccessoryRenderer, SvgFragment
```

**Contract:**
```typescript
interface RenderContext {
  cx: number; cy: number;   // spirit center in SVG coords
  half: number;              // icon half-size (varies by sm/md/lg)
  primaryColor: string;      // subject color
  accentColor: string;
  stage: number;             // evolution stage 1-3
  subject: 'chinese' | 'math' | 'english';
  mood: string;
  eyeOffsetX: number;        // eye tracking sync
  eyeOffsetY: number;
}

type AccessoryRenderer = (ctx: RenderContext) => { svg: string; offsetY?: number };
```

**Per-slot placement rules:**
- `head`: Above head center. Adjusted per subject (scholar=flat hat top, cat=between ears, wizard=on hat cone)
- `neck`: Below head, above body. Wraps with slight curve.
- `eyes`: Over eye region. Follows `eyeOffsetX/Y`.
- `effect`: Particle system orbiting spirit. Purely decorative.

**Image fallback:** Check `iconUrl` — if it's a real image URL (not emoji), render `<image>` instead. Same pattern as SpiritAvatar's `useImage`.

### 1.2 Room Theme System

New DB table `room_theme_def`:
```sql
CREATE TABLE IF NOT EXISTS room_theme_def (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  theme_key VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  icon_url VARCHAR(255),
  wall_gradient_top VARCHAR(20) DEFAULT '#fef9ef',
  wall_gradient_bottom VARCHAR(20) DEFAULT '#fef3c7',
  floor_color VARCHAR(20) DEFAULT '#d4a574',
  floor_plank_color VARCHAR(20) DEFAULT '#c49564',
  -- JSON fields for extensibility
  window_style VARCHAR(50) DEFAULT 'arched',
  lamp_style VARCHAR(50) DEFAULT 'pendant',
  ambient_particles VARCHAR(50),  -- 'stars','fireflies','petals','none'
  is_default BOOLEAN DEFAULT FALSE,
  sort_order INT DEFAULT 0
);
```

Seed 6 themes (1 default free + 5 collectible):
| key | name | unlock |
|-----|------|--------|
| cozy_warm | 温馨暖居 | Free (default) |
| starry_night | 星空夜语 | Shop 200⚡ |
| forest_green | 翠林幽居 | Shop 200⚡ |
| ancient_study | 古风书房 | Achievement |
| crystal_hall | 水晶殿堂 | Shop 500⚡ |
| ocean_deep | 深海小屋 | Gacha rare |

Themes as `item_def` entries with `category='ROOM_THEME'` so they flow through the existing shop/inventory/gacha pipeline.

Frontend theme registry at `frontend/src/lib/room/themes/registry.ts`:
```typescript
interface RoomTheme {
  key: string;
  name: string;
  wall: { gradient: [string, string]; pattern?: SvgPattern };
  floor: { color: string; plankColor: string };
  window: SvgRenderer;
  ceilingLamp: SvgRenderer;
  defaultRug: SvgRenderer;
  ambientParticles: ParticleDef[];
  colorScheme: { primary: string; secondary: string; accent: string };
}
```

### 1.3 Furniture SVG Rendering

Replace emoji `<text>` elements with hand-drawn SVG groups.

```
frontend/src/lib/room/furniture/
├── registry.ts        # itemKey → FurnitureRenderer
├── bed.ts             # Bed: frame + headboard + pillow + blanket
├── sofa.ts            # Sofa: rounded body + armrests + cushions
├── bookshelf.ts       # Bookshelf: frame + shelves + colored book spines
├── lamp.ts            # Lamp: pole + shade + pulsing glow
├── rug.ts             # Rug: ellipse + decorative border pattern
├── plant.ts           # Plant: pot + stem + leaves
├── window.ts          # Window: frame + glass pane + curtain drapes
├── poster.ts          # Poster: rect + decorative border + text lines
├── ball.ts            # Toy ball: circle + stripe pattern
├── mobile.ts          # Star mobile: hanging cord + dangling stars
├── table.ts           # Table: top surface + legs
├── clock.ts           # Clock: circle + hour/minute hands
└── types.ts           # FurnitureRenderContext, FurnitureRenderer
```

Each renderer: `(x: number, y: number, scale: number, theme: RoomTheme) => string` (SVG group inner HTML).

**Visual requirements:**
- Drop shadow under every furniture item (ground contact)
- Ambient light tint from theme's color scheme
- Scale-consistent (all furniture proportions relative to the 400×300 viewBox)

### 1.4 Room Scene Layering

Rewrite `PetRoomScene.svelte` with proper z-layering inside SVG:

```
Layer -2: Wall background (theme gradient + optional pattern)
Layer -1: Window + ceiling lamp + ambient particles (stars/fireflies)
Layer  0: Floor + baseboard
Layer  1: Back furniture (wall-mounted: poster, clock, window deco, mobile)
Layer  2: Spirit (center, standing on rug area)
Layer  3: Front furniture (floor-standing: bed, sofa, table, bookshelf, plant, ball)
Layer  4: Foreground effects (lamp glow overlay, rug)
Layer  5: Drag handles (when editing)
```

**Key fix:** Spirit returns INSIDE the SVG. Back furniture is behind spirit, front furniture is in front. `y` position determines layer — items with lower y are further back (wall), higher y are closer (floor).

### 1.5 Backend Changes

**New table:** `room_theme_def`
**Schema migration:** Add `room_theme_def` + idempotent ALTER for `pet_room.room_style` to store theme key
**New endpoint:** `PUT /api/v1/pet-room/theme` — change room theme
**Seed data:** 6 theme definitions + 6 ROOM_THEME item_def entries
**slot_data evolution:** Change from `{"slot_key": item_def_id}` to `{"furniture": [{"userItemId": N, "itemDefId": N, "x": 100, "y": 200}]}` for free-form placement

---

## Layer 2: Interaction Layer

**Goal:** The room becomes interactive and fun to decorate.

### 2.1 Free-Form Drag & Drop

- Use pointer events (not HTML5 drag API — better for SVG)
- Furniture items are draggable in edit mode
- Visual feedback: drag ghost, snap indicators, drop shadow intensifies on hover
- Position saved to backend on drop
- Collision prevention: furniture items can't overlap (minimum distance check)

### 2.2 Click Interactions

- Click spirit → speech bubble with personality quote (already have this, wire it in room)
- Click window → toggle day/night (visual only, persists per-session)
- Click lamp → toggle on/off (room gets darker/warmer)
- Click furniture → spirit walks to it and interacts (Layer 3)
- Click rug → spirit does a little spin/dance

### 2.3 Room State Persistence

- Furniture positions saved to `slot_data` JSON
- Day/night and lamp state saved (could be in slot_data or separate column)
- Theme saved to `room_style` column

---

## Layer 3: Autonomy Layer

**Goal:** The room feels alive. Spirit has its own behavior.

### 3.1 Spirit Autonomous Behavior

Simple state machine:
```
idle_stand → wander → sit_on_furniture → read_book → sleep → wake → idle_stand
```

- Each state has: duration range, animation, eligible furniture types
- Transitions triggered by timers + probability
- Spirit pathfinds to furniture positions (simple linear interpolation)
- States influenced by: happiness, energy, time of day, dormancy

### 3.2 Multi-Spirit Support

- If user has multiple spirits, others appear in room as "visitors"
- Each spirit has independent behavior state
- Spirits can interact: chat bubbles between two nearby spirits
- Active spirit is visually highlighted

### 3.3 Friend Visit Mode

- Visit friend's room (read-only + reactions)
- Leave emoji reactions on furniture/decoration
- "Like" button for the room overall
- Friend's spirit is the host, shown with a host badge

---

## Implementation Order

| Step | Content | Layer |
|:---:|------|:---:|
| 1 | Accessory SVG renderers (head/neck/eyes/effects) | 1 |
| 2 | Furniture SVG renderers (12 items) | 1 |
| 3 | Room theme registry + 6 themes | 1 |
| 4 | PetRoomScene rewrite (layering + theme + furniture) | 1 |
| 5 | Backend: room_theme_def table + theme endpoint | 1 |
| 6 | Backend: slot_data migration to free-form positions | 1 |
| 7 | Frontend: theme switching UI | 1 |
| 8 | Frontend: free-form drag & drop | 2 |
| 9 | Frontend: click interactions | 2 |
| 10 | Frontend: spirit autonomous behavior | 3 |
| 11 | Frontend: multi-spirit + visitors | 3 |
| 12 | Backend: friend visit endpoints | 3 |

## Verification

1. Spirit with hat/scarf/glasses — accessories are properly positioned SVG shapes
2. Room with furniture — items have shadows, correct layering, no emoji
3. Theme switching — wall/floor/window/lamp change correctly
4. Drag furniture — smooth, positions persist on reload
5. Spirit autonomy — wanders, sits, sleeps without user input
6. svelte-check 0 errors, mvn compile clean
7. Existing features (study/shop/spirit/accessories) unaffected
