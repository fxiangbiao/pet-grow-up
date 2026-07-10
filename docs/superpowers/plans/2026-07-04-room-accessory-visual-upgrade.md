# Room & Accessory Visual Upgrade — Layer 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace emoji-based spirit accessories and room furniture with hand-drawn SVG renderers, add 6 collectible room themes, and migrate room placement from fixed slots to free-form coordinates.

**Architecture:** Frontend renderer registries map `itemKey` → SVG renderer function. SpiritAvatar renders accessories inside its SVG via coordinate-aware renderers. PetRoomScene uses theme definitions for wall/floor/window/lamp, multi-layer SVG with z-sorting by y-position, and furniture renderers that produce SVG groups with drop shadows. Backend adds `room_theme_def` table, theme endpoint, and migrates `slot_data` from `{"slot_key": item_def_id}` to `[{"userItemId": N, "itemDefId": N, "itemKey": "...", "x": 100, "y": 200}]`.

**Tech Stack:** Svelte 5 runes, TypeScript, SVG, Spring Boot 3.2.4, MyBatis-Flex, MySQL 8.0, Jackson JSON

## Global Constraints

- All new frontend files use Svelte 5 runes and TypeScript
- All new backend files follow package-by-module pattern: `entity/mapper/dto/service/controller`
- All MyBatis-Flex mapper interfaces must have `@Mapper` from `org.apache.ibatis.annotations.Mapper`
- All schema changes use idempotent `SET @sql = IF(...)` prepared statements
- Furniture image fallback: check if `iconUrl` is an emoji → use SVG renderer; otherwise use `<image>` tag
- SpiritAvatar keeps existing `useImage` pattern for spirit body; accessory rendering is a new SVG layer
- svelte-check 0 errors, mvn compile clean at end of each task
- Do NOT modify existing study/shop/energy/spirit logic

---

## File Structure

```
frontend/src/lib/accessories/
├── types.ts                       # RenderContext, AccessoryRenderer, SvgFragment
├── registry.ts                    # Map<itemKey, AccessoryRenderer>
└── renderers/
    ├── head.ts                    # acc_hat_red, acc_bow_pink, acc_flower_ring, acc_graduation_cap
    ├── neck.ts                    # acc_scarf_blue, acc_bowtie, acc_star_necklace, acc_perseverance_scarf
    ├── eyes.ts                    # acc_round_glasses, acc_star_shades
    └── effects.ts                 # acc_effect_gold, acc_effect_rainbow

frontend/src/lib/room/
├── furniture/
│   ├── types.ts                   # FurnitureContext, FurnitureRenderer
│   ├── registry.ts                # Map<itemKey, FurnitureRenderer>
│   ├── bed.ts, sofa.ts, bookshelf.ts, lamp.ts, rug.ts, plant.ts
│   ├── window.ts, poster.ts, ball.ts, mobile.ts, table.ts, clock.ts
├── themes/
│   ├── types.ts                   # RoomTheme interface
│   ├── registry.ts                # Map<themeKey, RoomTheme>
│   ├── cozy-warm.ts, starry-night.ts, forest-green.ts
│   ├── ancient-study.ts, crystal-hall.ts, ocean-deep.ts

backend/src/main/java/com/petgrowup/room/
├── entity/RoomThemeDef.java       # New entity
├── mapper/RoomThemeDefMapper.java # New mapper
├── dto/ThemeDTO.java              # New DTO
├── dto/UpdatePositionRequest.java # New: {userItemId, x, y}
├── dto/ChangeThemeRequest.java    # New: {themeKey}

Modified:
- frontend/src/lib/components/spirit/SpiritAvatar.svelte
- frontend/src/lib/components/room/PetRoomScene.svelte (rewrite)
- frontend/src/lib/components/room/DecorationPicker.svelte
- frontend/src/routes/app/pet-room/+page.svelte
- frontend/src/lib/api/pet-room.ts
- backend/.../room/entity/PetRoom.java
- backend/.../room/dto/PetRoomDTO.java, PlaceItemRequest.java
- backend/.../room/service/PetRoomService.java
- backend/.../room/controller/PetRoomController.java
- backend/src/main/resources/schema.sql, data.sql
```

---

### Task 1: Accessory Rendering System (types + registry + 4 renderers)

**Files:**
- Create: `frontend/src/lib/accessories/types.ts`
- Create: `frontend/src/lib/accessories/registry.ts`
- Create: `frontend/src/lib/accessories/renderers/head.ts`
- Create: `frontend/src/lib/accessories/renderers/neck.ts`
- Create: `frontend/src/lib/accessories/renderers/eyes.ts`
- Create: `frontend/src/lib/accessories/renderers/effects.ts`

**Interfaces:**
- Produces: `RenderContext` interface, `AccessoryRenderer` type, `accessoryRegistry: Map<string, AccessoryRenderer>`

- [ ] **Step 1: Create types.ts**

```typescript
// frontend/src/lib/accessories/types.ts

export interface RenderContext {
  cx: number;
  cy: number;
  half: number;           // icon half-size, varies by sm/md/lg
  primaryColor: string;
  secondaryColor: string;
  accentColor: string;
  stage: number;          // evolution stage 1-3
  subject: 'chinese' | 'math' | 'english';
  eyeOffsetX: number;     // eye tracking offset
  eyeOffsetY: number;
}

export interface SvgFragment {
  svg: string;            // SVG inner HTML (no <svg> wrapper)
  offsetY?: number;       // optional vertical adjustment
}

export type AccessoryRenderer = (ctx: RenderContext) => SvgFragment;
```

- [ ] **Step 2: Create registry.ts**

```typescript
// frontend/src/lib/accessories/registry.ts
import type { AccessoryRenderer } from './types';
import { headRenderers } from './renderers/head';
import { neckRenderers } from './renderers/neck';
import { eyesRenderers } from './renderers/eyes';
import { effectsRenderers } from './renderers/effects';

export const accessoryRegistry: Map<string, AccessoryRenderer> = new Map([
  ...Object.entries(headRenderers),
  ...Object.entries(neckRenderers),
  ...Object.entries(eyesRenderers),
  ...Object.entries(effectsRenderers),
]);

export function getAccessoryRenderer(itemKey: string): AccessoryRenderer | undefined {
  return accessoryRegistry.get(itemKey);
}
```

- [ ] **Step 3: Create head renderers (head.ts)**

```typescript
// frontend/src/lib/accessories/renderers/head.ts
import type { AccessoryRenderer } from '../types';

// Helper: adjust hat Y based on subject
function hatAnchorY(ctx: { subject: string; cy: number; half: number }): number {
  switch (ctx.subject) {
    case 'chinese': return ctx.cy - ctx.half * 0.52;  // above flat hat
    case 'math':    return ctx.cy - ctx.half * 0.55;  // between cat ears
    case 'english': return ctx.cy - ctx.half * 0.68;  // on wizard hat cone
    default:        return ctx.cy - ctx.half * 0.5;
  }
}

function renderRedHat(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx);
  const w = ctx.half * 0.5;
  const h = ctx.half * 0.22;
  const cx = ctx.cx;
  // Red cap: rounded dome + brim
  return `
    <ellipse cx="${cx}" cy="${y}" rx="${w}" ry="${h}" fill="#ef4444" stroke="#b91c1c" stroke-width="1"/>
    <rect x="${cx - w * 1.05}" y="${y}" width="${w * 2.1}" height="${h * 0.35}" rx="2" fill="#dc2626"/>
    <circle cx="${cx}" cy="${y - h * 0.4}" r="${h * 0.25}" fill="#fbbf24"/>
  `;
}

function renderBow(ctx: { cx: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx) + ctx.half * 0.05;
  const s = ctx.half * 0.22;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx - s}" cy="${y - s * 0.5}" rx="${s}" ry="${s * 0.7}" fill="#f472b6" transform="rotate(-20,${cx - s},${y - s * 0.5})"/>
    <ellipse cx="${cx + s}" cy="${y - s * 0.5}" rx="${s}" ry="${s * 0.7}" fill="#f472b6" transform="rotate(20,${cx + s},${y - s * 0.5})"/>
    <circle cx="${cx}" cy="${y}" r="${s * 0.3}" fill="#ec4899"/>
  `;
}

function renderFlowerCrown(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx) + ctx.half * 0.08;
  const r = ctx.half * 0.55;
  const cx = ctx.cx;
  const flowers = [0, 60, 120, 180, 240, 300].map((angle, i) => {
    const fx = cx + r * Math.cos((angle * Math.PI) / 180);
    const fy = y + r * Math.sin((angle * Math.PI) / 180) * 0.4;
    const colors = ['#fbbf24', '#f472b6', '#a78bfa', '#fb923c', '#f87171', '#fbbf24'];
    return `<circle cx="${fx}" cy="${fy}" r="${ctx.half * 0.1}" fill="${colors[i]}" opacity="0.9"/>`;
  }).join('');
  return flowers;
}

function renderGraduationCap(ctx: { cx: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx);
  const w = ctx.half * 0.45;
  const h = ctx.half * 0.1;
  const cx = ctx.cx;
  return `
    <rect x="${cx - w}" y="${y - h}" width="${w * 2}" height="${h}" fill="#1e3a5f" rx="1"/>
    <rect x="${cx - w * 0.6}" y="${y}" width="${w * 1.2}" height="${h * 0.7}" fill="#1e40af" rx="1"/>
    <polygon points="${cx - w * 0.5},${y - h} ${cx + w * 0.5},${y - h} ${cx},${y - h * 1.2}" fill="#1e3a5f"/>
    <line x1="${cx - w * 0.8}" y1="${y - h}" x2="${cx + w * 1.2}" y2="${y - h}" stroke="#fbbf24" stroke-width="1.5"/>
    <circle cx="${cx + w * 1.2}" cy="${y - h}" r="2" fill="#fbbf24"/>
  `;
}

export const headRenderers: Record<string, AccessoryRenderer> = {
  acc_hat_red:        (ctx) => ({ svg: renderRedHat(ctx) }),
  acc_bow_pink:       (ctx) => ({ svg: renderBow(ctx) }),
  acc_flower_ring:    (ctx) => ({ svg: renderFlowerCrown(ctx) }),
  acc_graduation_cap: (ctx) => ({ svg: renderGraduationCap(ctx) }),
};
```

- [ ] **Step 4: Create neck renderers (neck.ts)**

```typescript
// frontend/src/lib/accessories/renderers/neck.ts
import type { AccessoryRenderer } from '../types';

function neckY(ctx: { cy: number; half: number; subject: string }): number {
  // Neck is just below head
  switch (ctx.subject) {
    case 'chinese': return ctx.cy + ctx.half * 0.15;
    case 'math':    return ctx.cy + ctx.half * 0.18;
    case 'english': return ctx.cy + ctx.half * 0.17;
    default:        return ctx.cy + ctx.half * 0.15;
  }
}

function renderBlueScarf(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = neckY(ctx);
  const w = ctx.half * 0.4;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx}" cy="${y}" rx="${w}" ry="${ctx.half * 0.12}" fill="#60a5fa" stroke="#3b82f6" stroke-width="1"/>
    <rect x="${cx + w * 0.3}" y="${y + ctx.half * 0.05}" width="${w * 0.25}" height="${ctx.half * 0.35}" fill="#3b82f6" rx="2" transform="rotate(10,${cx + w * 0.3},${y + ctx.half * 0.05})"/>
    <line x1="${cx - w * 0.9}" y1="${y}" x2="${cx - w * 0.7}" y2="${y + ctx.half * 0.08}" stroke="#93c5fd" stroke-width="1.5" stroke-linecap="round"/>
  `;
}

function renderBowtie(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = neckY(ctx);
  const s = ctx.half * 0.15;
  const cx = ctx.cx;
  return `
    <polygon points="${cx - s},${y - s} ${cx},${y} ${cx - s},${y + s}" fill="#ef4444"/>
    <polygon points="${cx + s},${y - s} ${cx},${y} ${cx + s},${y + s}" fill="#ef4444"/>
    <circle cx="${cx}" cy="${y}" r="${s * 0.3}" fill="#dc2626"/>
  `;
}

function renderStarNecklace(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = neckY(ctx);
  const cx = ctx.cx;
  const r = ctx.half * 0.35;
  // Chain arc
  return `
    <path d="M${cx - r},${y - ctx.half * 0.1} Q${cx - r * 0.7},${y + ctx.half * 0.2} ${cx},${y + ctx.half * 0.08} Q${cx + r * 0.7},${y + ctx.half * 0.2} ${cx + r},${y - ctx.half * 0.1}"
      fill="none" stroke="#fbbf24" stroke-width="1.2" stroke-dasharray="2,1"/>
    <polygon points="${cx},${y + ctx.half * 0.02} ${cx + 3},${y + ctx.half * 0.1} ${cx + 8},${y + ctx.half * 0.1} ${cx + 4},${y + ctx.half * 0.15} ${cx + 5},${y + ctx.half * 0.22} ${cx},${y + ctx.half * 0.18} ${cx - 5},${y + ctx.half * 0.22} ${cx - 4},${y + ctx.half * 0.15} ${cx - 8},${y + ctx.half * 0.1} ${cx - 3},${y + ctx.half * 0.1}"
      fill="#fbbf24" stroke="#f59e0b" stroke-width="0.5"/>
  `;
}

function renderPerseveranceScarf(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = neckY(ctx);
  const w = ctx.half * 0.42;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx}" cy="${y}" rx="${w}" ry="${ctx.half * 0.13}" fill="#fbbf24" stroke="#f59e0b" stroke-width="1.2"/>
    <rect x="${cx + w * 0.25}" y="${y + ctx.half * 0.04}" width="${w * 0.22}" height="${ctx.half * 0.38}" fill="#f59e0b" rx="2" transform="rotate(8,${cx + w * 0.25},${y + ctx.half * 0.04})"/>
    <text x="${cx}" y="${y + 3}" text-anchor="middle" font-size="${ctx.half * 0.15}" fill="#d97706">★</text>
  `;
}

export const neckRenderers: Record<string, AccessoryRenderer> = {
  acc_scarf_blue:          (ctx) => ({ svg: renderBlueScarf(ctx) }),
  acc_bowtie:              (ctx) => ({ svg: renderBowtie(ctx) }),
  acc_star_necklace:       (ctx) => ({ svg: renderStarNecklace(ctx) }),
  acc_perseverance_scarf:  (ctx) => ({ svg: renderPerseveranceScarf(ctx) }),
};
```

- [ ] **Step 5: Create eyes renderers (eyes.ts)**

```typescript
// frontend/src/lib/accessories/renderers/eyes.ts
import type { AccessoryRenderer } from '../types';

function eyeCenter(ctx: { cy: number; half: number }): number {
  return ctx.cy - ctx.half * 0.08; // matches SpiritAvatar eyeY
}

function renderRoundGlasses(ctx: { cx: number; cy: number; half: number; eyeOffsetX: number; eyeOffsetY: number }): string {
  const ey = eyeCenter(ctx);
  const es = ctx.half * 0.3;  // eye spacing
  const er = ctx.half * 0.11; // lens radius
  const cx = ctx.cx;
  const ox = ctx.eyeOffsetX;
  const oy = ctx.eyeOffsetY;
  return `
    <circle cx="${cx - es + ox}" cy="${ey + oy}" r="${er}" fill="none" stroke="#374151" stroke-width="1.5" opacity="0.7"/>
    <circle cx="${cx + es + ox}" cy="${ey + oy}" r="${er}" fill="none" stroke="#374151" stroke-width="1.5" opacity="0.7"/>
    <line x1="${cx - es + er + ox}" y1="${ey + oy}" x2="${cx + es - er + ox}" y2="${ey + oy}" stroke="#374151" stroke-width="1" opacity="0.5"/>
  `;
}

function renderStarShades(ctx: { cx: number; cy: number; half: number; eyeOffsetX: number; eyeOffsetY: number }): string {
  const ey = eyeCenter(ctx);
  const es = ctx.half * 0.3;
  const rs = ctx.half * 0.13;
  const cx = ctx.cx;
  const ox = ctx.eyeOffsetX;
  const oy = ctx.eyeOffsetY;
  const star = (sx: number, sy: number) => {
    const pts: string[] = [];
    for (let i = 0; i < 5; i++) {
      const a = (Math.PI / 2.5) * i - Math.PI / 2;
      pts.push(`${sx + rs * Math.cos(a)},${sy + rs * Math.sin(a)}`);
    }
    return pts.join(' ');
  };
  return `
    <polygon points="${star(cx - es + ox, ey + oy)}" fill="#1e1b4b" stroke="#fbbf24" stroke-width="1" opacity="0.8"/>
    <polygon points="${star(cx + es + ox, ey + oy)}" fill="#1e1b4b" stroke="#fbbf24" stroke-width="1" opacity="0.8"/>
    <line x1="${cx - es + rs + ox}" y1="${ey + oy}" x2="${cx + es - rs + ox}" y2="${ey + oy}" stroke="#fbbf24" stroke-width="0.8" opacity="0.5"/>
  `;
}

export const eyesRenderers: Record<string, AccessoryRenderer> = {
  acc_round_glasses: (ctx) => ({ svg: renderRoundGlasses(ctx) }),
  acc_star_shades:   (ctx) => ({ svg: renderStarShades(ctx) }),
};
```

- [ ] **Step 6: Create effects renderers (effects.ts)**

```typescript
// frontend/src/lib/accessories/renderers/effects.ts
import type { AccessoryRenderer } from '../types';

function renderGoldSparkle(ctx: { cx: number; cy: number; half: number }): string {
  const r = ctx.half * 0.8;
  const cx = ctx.cx;
  const cy = ctx.cy;
  // 6 orbiting golden particles with animation
  return [0, 60, 120, 180, 240, 300].map((angle, i) => {
    const px = cx + r * Math.cos((angle * Math.PI) / 180);
    const py = cy + r * Math.sin((angle * Math.PI) / 180);
    return `<circle cx="${px}" cy="${py}" r="2.5" fill="#fbbf24" opacity="0.8">
      <animate attributeName="opacity" values="0.3;1;0.3" dur="${1.5 + i * 0.2}s" repeatCount="indefinite"/>
      <animate attributeName="r" values="1.5;3;1.5" dur="${1.5 + i * 0.2}s" repeatCount="indefinite"/>
    </circle>`;
  }).join('');
}

function renderRainbowAura(ctx: { cx: number; cy: number; half: number; stage: number }): string {
  const r = ctx.half * 0.75;
  const cx = ctx.cx;
  const cy = ctx.cy;
  const colors = ['#ef4444', '#f97316', '#fbbf24', '#22c55e', '#3b82f6', '#8b5cf6'];
  return colors.map((c, i) => {
    const offset = ctx.stage >= 2 ? i * 0.3 : i * 0.15;
    return `<ellipse cx="${cx}" cy="${cy}" rx="${r + i * 3}" ry="${r * 0.6 + i * 2}" fill="none" stroke="${c}" stroke-width="1.5" opacity="0.4">
      <animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" begin="${offset}s" repeatCount="indefinite"/>
    </ellipse>`;
  }).join('');
}

export const effectsRenderers: Record<string, AccessoryRenderer> = {
  acc_effect_gold:    (ctx) => ({ svg: renderGoldSparkle(ctx) }),
  acc_effect_rainbow: (ctx) => ({ svg: renderRainbowAura(ctx) }),
};
```

- [ ] **Step 7: Verify — run svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -5
```
Expected: 0 errors

---

### Task 2: Integrate Accessories into SpiritAvatar

**Files:**
- Modify: `frontend/src/lib/components/spirit/SpiritAvatar.svelte`

**Interfaces:**
- Consumes: `accessoryRegistry` from Task 1, `RenderContext` from Task 1
- Produces: Updated SpiritAvatar that renders accessories as SVG inside the spirit SVG (replacing emoji spans)

- [ ] **Step 1: Add imports and build render context**

In `SpiritAvatar.svelte`, add import after line 2:
```typescript
import { getAccessoryRenderer } from '$lib/accessories/registry';
import type { RenderContext } from '$lib/accessories/types';
```

- [ ] **Step 2: Build RenderContext from existing props**

Add after the existing derived values (around line 164):
```typescript
const renderCtx = $derived<RenderContext>({
  cx,
  cy,
  half,
  primaryColor: primaryHex,
  secondaryColor: secondaryHex,
  accentColor: accentHex,
  stage,
  subject: species?.subject as 'chinese' | 'math' | 'english' ?? 'chinese',
  eyeOffsetX,
  eyeOffsetY,
});
```

- [ ] **Step 3: Compute rendered accessory SVG strings**

Add after renderCtx:
```typescript
const renderedAccessories = $derived.by(() => {
  return accessories.map(acc => {
    const renderer = getAccessoryRenderer(acc.itemKey || acc.name);
    if (!renderer) return null;
    try {
      const fragment = renderer(renderCtx);
      return { ...acc, svg: fragment.svg };
    } catch {
      return null;
    }
  }).filter(Boolean) as { slot: string; name: string; svg: string }[];
});
```

- [ ] **Step 4: Replace emoji spans with SVG group**

Replace lines 517-530 (the `{#if accessories.length > 0}` block) with:
```svelte
<!-- Sprint E+F: Accessory SVG renderers (inside the spirit SVG) -->
{#if renderedAccessories.length > 0}
  <g class="accessories-layer" pointer-events="none">
    {@html renderedAccessories.map(a => a.svg).join('')}
  </g>
{/if}
```

This goes inside the SVG element (after the facial features section, before the `</svg>` closing tag), replacing the outer `<div>` with emoji spans.

- [ ] **Step 5: Remove old emoji accessory rendering**

Delete the old accessory div (lines 517-530 in original file):
```
<!-- Sprint E: Accessory emojis -->
{#if accessories.length > 0}
  <div class="absolute inset-0 pointer-events-none flex items-center justify-center">
    {#each accessories as acc}
      <span class="absolute text-xs leading-none" ...>
    {/each}
  </div>
{/if}
```

- [ ] **Step 6: Verify svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -5
```
Expected: 0 errors

---

### Task 3: Furniture SVG Rendering System (types + registry + 12 renderers)

**Files:**
- Create: `frontend/src/lib/room/furniture/types.ts`
- Create: `frontend/src/lib/room/furniture/registry.ts`
- Create: `frontend/src/lib/room/furniture/bed.ts`
- Create: `frontend/src/lib/room/furniture/sofa.ts`
- Create: `frontend/src/lib/room/furniture/bookshelf.ts`
- Create: `frontend/src/lib/room/furniture/lamp.ts`
- Create: `frontend/src/lib/room/furniture/rug.ts`
- Create: `frontend/src/lib/room/furniture/plant.ts`
- Create: `frontend/src/lib/room/furniture/window.ts`
- Create: `frontend/src/lib/room/furniture/poster.ts`
- Create: `frontend/src/lib/room/furniture/ball.ts`
- Create: `frontend/src/lib/room/furniture/mobile.ts`
- Create: `frontend/src/lib/room/furniture/table.ts`
- Create: `frontend/src/lib/room/furniture/clock.ts`

**Interfaces:**
- Produces: `FurnitureContext`, `FurnitureRenderer`, `furnitureRegistry: Map<string, FurnitureRenderer>`

- [ ] **Step 1: Create types.ts**

```typescript
// frontend/src/lib/room/furniture/types.ts

export interface FurnitureContext {
  x: number;              // center x in room SVG (0-400)
  y: number;              // center y in room SVG (0-300)
  scale: number;          // 1.0 = default, can scale
  floorY: number;         // y position of floor line (200)
}

export type FurnitureRenderer = (ctx: FurnitureContext) => string;
// Returns SVG group inner HTML including drop shadow filter reference
```

- [ ] **Step 2: Create registry.ts**

```typescript
// frontend/src/lib/room/furniture/registry.ts
import type { FurnitureRenderer } from './types';
import { renderBed } from './bed';
import { renderSofa } from './sofa';
import { renderBookshelf } from './bookshelf';
import { renderLamp } from './lamp';
import { renderRug } from './rug';
import { renderPlant } from './plant';
import { renderWindowDeco } from './window';
import { renderPoster } from './poster';
import { renderBall } from './ball';
import { renderMobile } from './mobile';
import { renderTable } from './table';
import { renderClock } from './clock';

export const furnitureRegistry: Map<string, FurnitureRenderer> = new Map([
  ['deco_bed_small',    renderBed],
  ['deco_sofa',         renderSofa],
  ['deco_bookshelf',    renderBookshelf],
  ['deco_lamp',         renderLamp],
  ['deco_rug_round',    renderRug],
  ['deco_plant',        renderPlant],
  ['deco_window',       renderWindowDeco],
  ['deco_poster',       renderPoster],
  ['deco_toy_ball',     renderBall],
  ['deco_star_mobile',  renderMobile],
  ['deco_table',        renderTable],
  ['deco_clock',        renderClock],
]);

export function getFurnitureRenderer(itemKey: string): FurnitureRenderer | undefined {
  return furnitureRegistry.get(itemKey);
}
```

- [ ] **Step 3: Create bed.ts (floor furniture, ~60x40)**

```typescript
// frontend/src/lib/room/furniture/bed.ts
import type { FurnitureRenderer } from './types';

export const renderBed: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 30 * s, h = 18 * s;
  return `
    <!-- Bed shadow -->
    <ellipse cx="${x}" cy="${y + h * 0.5 + 2}" rx="${w * 0.9}" ry="4" fill="rgba(0,0,0,0.12)"/>
    <!-- Bed frame -->
    <rect x="${x - w}" y="${y - h * 0.4}" width="${w * 2}" height="${h}" rx="3" fill="#d4a574" stroke="#b8875a" stroke-width="1"/>
    <!-- Headboard -->
    <rect x="${x - w}" y="${y - h * 0.7}" width="${w * 2}" height="${h * 0.4}" rx="2" fill="#c49564" stroke="#a0704a" stroke-width="0.8"/>
    <!-- Pillow -->
    <ellipse cx="${x - w * 0.5}" cy="${y - h * 0.25}" rx="${w * 0.6}" ry="${h * 0.25}" fill="#fff" opacity="0.9"/>
    <!-- Blanket -->
    <rect x="${x - w * 0.3}" y="${y - h * 0.2}" width="${w * 1.3}" height="${h * 0.7}" rx="2" fill="#93c5fd" opacity="0.8"/>
    <line x1="${x - w * 0.2}" y1="${y - h * 0.2}" x2="${x - w * 0.2}" y2="${y + h * 0.5}" stroke="#60a5fa" stroke-width="0.5" opacity="0.5"/>
    <line x1="${x + w * 0.3}" y1="${y - h * 0.2}" x2="${x + w * 0.3}" y2="${y + h * 0.5}" stroke="#60a5fa" stroke-width="0.5" opacity="0.5"/>
  `;
};
```

- [ ] **Step 4: Create sofa.ts (floor furniture, ~50x30)**

```typescript
// frontend/src/lib/room/furniture/sofa.ts
import type { FurnitureRenderer } from './types';

export const renderSofa: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 25 * s, h = 14 * s;
  return `
    <ellipse cx="${x}" cy="${y + h * 0.5 + 2}" rx="${w * 0.8}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <!-- Sofa body -->
    <rect x="${x - w}" y="${y - h * 0.3}" width="${w * 2}" height="${h}" rx="4" fill="#fbbf24" stroke="#f59e0b" stroke-width="1"/>
    <!-- Armrests -->
    <rect x="${x - w}" y="${y - h * 0.5}" width="${w * 0.3}" height="${h * 0.7}" rx="3" fill="#f59e0b"/>
    <rect x="${x + w - w * 0.3}" y="${y - h * 0.5}" width="${w * 0.3}" height="${h * 0.7}" rx="3" fill="#f59e0b"/>
    <!-- Seat cushions -->
    <rect x="${x - w * 0.6}" y="${y - h * 0.3}" width="${w * 0.7}" height="${h * 0.4}" rx="2" fill="#fef3c7"/>
    <rect x="${x + w * 0.05}" y="${y - h * 0.3}" width="${w * 0.7}" height="${h * 0.4}" rx="2" fill="#fef3c7"/>
  `;
};
```

- [ ] **Step 5: Create bookshelf.ts (wall furniture, ~30x55)**

```typescript
// frontend/src/lib/room/furniture/bookshelf.ts
import type { FurnitureRenderer } from './types';

export const renderBookshelf: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 15 * s, h = 27 * s;
  const colors = ['#ef4444','#3b82f6','#22c55e','#fbbf24','#a855f7','#ec4899','#f97316','#06b6d4'];
  return `
    <!-- Frame -->
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 2}" rx="1" fill="#8B5E3C" stroke="#6B3F2C" stroke-width="1"/>
    <!-- Shelves -->
    <line x1="${x - w + 2}" y1="${y - h + h * 0.5}" x2="${x + w - 2}" y2="${y - h + h * 0.5}" stroke="#6B3F2C" stroke-width="1"/>
    <line x1="${x - w + 2}" y1="${y - h + h * 1.0}" x2="${x + w - 2}" y2="${y - h + h * 1.0}" stroke="#6B3F2C" stroke-width="1"/>
    <line x1="${x - w + 2}" y1="${y - h + h * 1.5}" x2="${x + w - 2}" y2="${y - h + h * 1.5}" stroke="#6B3F2C" stroke-width="1"/>
    <!-- Books on shelf 1 -->
    ${[0,1,2,3].map(i => `
      <rect x="${x - w + 3 + i * 7}" y="${y - h + h * 0.1}" width="5" height="${h * 0.35}" fill="${colors[i]}" rx="0.5" opacity="0.8"/>
    `).join('')}
    <!-- Books on shelf 2 -->
    ${[0,1,2].map(i => `
      <rect x="${x - w + 4 + i * 8}" y="${y - h + h * 0.6}" width="5" height="${h * 0.35}" fill="${colors[i + 4]}" rx="0.5" opacity="0.8"/>
    `).join('')}
    <!-- Stack on shelf 3 -->
    <rect x="${x - w + 5}" y="${y - h + h * 1.4}" width="14" height="3" fill="#ef4444" rx="0.5" opacity="0.7"/>
    <rect x="${x - w + 6}" y="${y - h + h * 1.35}" width="13" height="3" fill="#3b82f6" rx="0.5" opacity="0.7"/>
  `;
};
```

- [ ] **Step 6: Create lamp.ts (hanging floor, ~15x40)**

```typescript
// frontend/src/lib/room/furniture/lamp.ts
import type { FurnitureRenderer } from './types';

export const renderLamp: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <ellipse cx="${x}" cy="${y + 10}" rx="${8 * s}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <!-- Pole -->
    <line x1="${x}" y1="${y - 20 * s}" x2="${x}" y2="${y + 8 * s}" stroke="#6b7280" stroke-width="2"/>
    <!-- Base -->
    <ellipse cx="${x}" cy="${y + 8 * s}" rx="${6 * s}" ry="${2 * s}" fill="#4b5563"/>
    <!-- Shade -->
    <polygon points="${x - 8 * s},${y - 15 * s} ${x + 8 * s},${y - 15 * s} ${x + 5 * s},${y - 22 * s} ${x - 5 * s},${y - 22 * s}"
      fill="#fef3c7" stroke="#f59e0b" stroke-width="0.8"/>
    <!-- Glow -->
    <circle cx="${x}" cy="${y - 15 * s}" r="${10 * s}" fill="url(#lampGlow)" opacity="0.4">
      <animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" repeatCount="indefinite"/>
    </circle>
  `;
};
```

- [ ] **Step 7: Create rug.ts (floor, ~80x15)**

```typescript
// frontend/src/lib/room/furniture/rug.ts
import type { FurnitureRenderer } from './types';

export const renderRug: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const rx = 35 * s, ry = 10 * s;
  return `
    <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#f472b6" opacity="0.3"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.85}" ry="${ry * 0.75}" fill="none" stroke="#ec4899" stroke-width="0.8" opacity="0.4"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.6}" ry="${ry * 0.45}" fill="none" stroke="#ec4899" stroke-width="0.5" opacity="0.3" stroke-dasharray="3,3"/>
  `;
};
```

- [ ] **Step 8: Create plant.ts (floor, ~20x35)**

```typescript
// frontend/src/lib/room/furniture/plant.ts
import type { FurnitureRenderer } from './types';

export const renderPlant: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <ellipse cx="${x}" cy="${y + 4}" rx="${7 * s}" ry="2" fill="rgba(0,0,0,0.1)"/>
    <!-- Pot -->
    <polygon points="${x - 5 * s},${y - 6 * s} ${x + 5 * s},${y - 6 * s} ${x + 4 * s},${y + 3 * s} ${x - 4 * s},${y + 3 * s}"
      fill="#d97706" stroke="#b45309" stroke-width="0.8"/>
    <rect x="${x - 5.5 * s}" y="${y - 7 * s}" width="${11 * s}" height="${1.5 * s}" rx="1" fill="#b45309"/>
    <!-- Stem -->
    <line x1="${x}" y1="${y - 7 * s}" x2="${x}" y2="${y - 18 * s}" stroke="#22c55e" stroke-width="1.5"/>
    <!-- Leaves -->
    <ellipse cx="${x - 4 * s}" cy="${y - 13 * s}" rx="${5 * s}" ry="${3 * s}" fill="#22c55e" transform="rotate(-30,${x - 4 * s},${y - 13 * s})"/>
    <ellipse cx="${x + 4 * s}" cy="${y - 15 * s}" rx="${5 * s}" ry="${3 * s}" fill="#16a34a" transform="rotate(25,${x + 4 * s},${y - 15 * s})"/>
    <ellipse cx="${x - 1 * s}" cy="${y - 18 * s}" rx="${4 * s}" ry="${2.5 * s}" fill="#4ade80" transform="rotate(-10,${x - 1 * s},${y - 18 * s})"/>
  `;
};
```

- [ ] **Step 9: Create remaining 6 furniture renderers**

Create: `frontend/src/lib/room/furniture/window.ts`
```typescript
import type { FurnitureRenderer } from './types';
export const renderWindowDeco: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 22 * s, h = 22 * s;
  return `
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 2}" rx="3" fill="#87CEEB" stroke="#8B7355" stroke-width="2"/>
    <line x1="${x}" y1="${y - h}" x2="${x}" y2="${y + h}" stroke="#8B7355" stroke-width="1.5"/>
    <line x1="${x - w}" y1="${y}" x2="${x + w}" y2="${y}" stroke="#8B7355" stroke-width="1.5"/>
    ${[0.3, 0.6, 0.2, 0.7].map(pos => `<circle cx="${x - w + pos * w * 2}" cy="${y - h + 6 * s}" r="2" fill="#FFD700" opacity="0.8"/>`).join('')}
    <!-- Curtains -->
    <rect x="${x - w - 1}" y="${y - h - 1}" width="6" height="${h * 2 + 2}" fill="#ffb3ba" rx="2" opacity="0.7"/>
    <rect x="${x + w - 5}" y="${y - h - 1}" width="6" height="${h * 2 + 2}" fill="#ffb3ba" rx="2" opacity="0.7"/>
  `;
};
```

Create: `frontend/src/lib/room/furniture/poster.ts`
```typescript
import type { FurnitureRenderer } from './types';
export const renderPoster: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 14 * s, h = 20 * s;
  return `
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 2}" rx="1" fill="#fef3c7" stroke="#d4a574" stroke-width="1"/>
    <rect x="${x - w + 3}" y="${y - h + 3}" width="${w * 2 - 6}" height="${h * 2 - 6}" fill="none" stroke="#f59e0b" stroke-width="0.5" rx="1"/>
    ${[0.3, 0.45, 0.6, 0.75].map(py => `<line x1="${x - w + 5}" y1="${y - h + py * h * 2}" x2="${x + w - 5}" y2="${y - h + py * h * 2}" stroke="#d4a574" stroke-width="0.8" opacity="0.5"/>`).join('')}
    <!-- Star on poster -->
    <text x="${x}" y="${y - h * 0.2}" text-anchor="middle" font-size="${6 * s}" fill="#f59e0b">★</text>
  `;
};
```

Create: `frontend/src/lib/room/furniture/ball.ts`
```typescript
import type { FurnitureRenderer } from './types';
export const renderBall: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const r = 10 * s;
  return `
    <ellipse cx="${x}" cy="${y + r * 0.8}" rx="${r * 0.7}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="#ef4444"/>
    <path d="M${x - r},${y} Q${x},${y - r} ${x + r},${y}" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
    <path d="M${x - r * 0.7},${y + r * 0.7} Q${x},${y} ${x + r * 0.7},${y - r * 0.7}" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
  `;
};
```

Create: `frontend/src/lib/room/furniture/mobile.ts` (ceiling-hung)
```typescript
import type { FurnitureRenderer } from './types';
export const renderMobile: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <line x1="${x}" y1="${y - 22 * s}" x2="${x}" y2="${y + 5 * s}" stroke="#9ca3af" stroke-width="0.8"/>
    <line x1="${x}" y1="${y - 2 * s}" x2="${x - 12 * s}" y2="${y + 10 * s}" stroke="#9ca3af" stroke-width="0.5"/>
    <line x1="${x}" y1="${y - 2 * s}" x2="${x + 12 * s}" y2="${y + 10 * s}" stroke="#9ca3af" stroke-width="0.5"/>
    <polygon points="${x},${y + 5 * s} ${x + 4},${y + 11 * s} ${x + 8},${y + 11 * s} ${x + 5},${y + 14 * s} ${x + 6},${y + 19 * s} ${x},${y + 16 * s} ${x - 6},${y + 19 * s} ${x - 5},${y + 14 * s} ${x - 8},${y + 11 * s} ${x - 4},${y + 11 * s}"
      fill="#fbbf24" opacity="0.8">
      <animateTransform attributeName="transform" type="rotate" values="-5,${x},${y - 22 * s};5,${x},${y - 22 * s};-5,${x},${y - 22 * s}" dur="4s" repeatCount="indefinite"/>
    </polygon>
  `;
};
```

Create: `frontend/src/lib/room/furniture/table.ts`
```typescript
import type { FurnitureRenderer } from './types';
export const renderTable: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 18 * s, h = 5 * s;
  return `
    <ellipse cx="${x}" cy="${y + h + 2}" rx="${w * 0.8}" ry="2" fill="rgba(0,0,0,0.1)"/>
    <!-- Legs -->
    <line x1="${x - w * 0.6}" y1="${y}" x2="${x - w * 0.5}" y2="${y + h + 3}" stroke="#8B7355" stroke-width="2"/>
    <line x1="${x + w * 0.6}" y1="${y}" x2="${x + w * 0.5}" y2="${y + h + 3}" stroke="#8B7355" stroke-width="2"/>
    <!-- Surface -->
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 1.5}" rx="2" fill="#d4a574" stroke="#b8875a" stroke-width="1"/>
  `;
};
```

Create: `frontend/src/lib/room/furniture/clock.ts`
```typescript
import type { FurnitureRenderer } from './types';
export const renderClock: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const r = 10 * s;
  return `
    <circle cx="${x}" cy="${y}" r="${r}" fill="#fff" stroke="#8B7355" stroke-width="1.5"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.85}" fill="none" stroke="#d4a574" stroke-width="0.5"/>
    <!-- Hour hand (pointing to ~10) -->
    <line x1="${x}" y1="${y}" x2="${x - r * 0.35}" y2="${y - r * 0.45}" stroke="#374151" stroke-width="1.5" stroke-linecap="round"/>
    <!-- Minute hand (pointing to ~2) -->
    <line x1="${x}" y1="${y}" x2="${x + r * 0.4}" y2="${y - r * 0.3}" stroke="#374151" stroke-width="1" stroke-linecap="round"/>
    <circle cx="${x}" cy="${y}" r="1.5" fill="#ef4444"/>
  `;
};
```

- [ ] **Step 10: Verify svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -5
```
Expected: 0 errors

---

### Task 4: Room Theme System (types + registry + 6 themes)

**Files:**
- Create: `frontend/src/lib/room/themes/types.ts`
- Create: `frontend/src/lib/room/themes/registry.ts`
- Create: `frontend/src/lib/room/themes/cozy-warm.ts`
- Create: `frontend/src/lib/room/themes/starry-night.ts`
- Create: `frontend/src/lib/room/themes/forest-green.ts`
- Create: `frontend/src/lib/room/themes/ancient-study.ts`
- Create: `frontend/src/lib/room/themes/crystal-hall.ts`
- Create: `frontend/src/lib/room/themes/ocean-deep.ts`

**Interfaces:**
- Produces: `RoomTheme` interface, `themeRegistry: Map<string, RoomTheme>`

- [ ] **Step 1: Create types.ts**

```typescript
// frontend/src/lib/room/themes/types.ts

export interface RoomTheme {
  key: string;
  name: string;
  icon: string;           // emoji icon for theme picker
  description: string;
  wall: {
    gradient: [string, string];  // [top, bottom]
    pattern?: 'stars' | 'leaves' | 'bamboo' | 'crystal' | 'waves' | 'none';
  };
  floor: {
    color: string;         // main floor fill
    plankColor: string;    // floor lines
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
```

- [ ] **Step 2: Create cozy-warm.ts (default, free)**

```typescript
// frontend/src/lib/room/themes/cozy-warm.ts
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
```

- [ ] **Step 3: Create starry-night.ts (shop 200⚡)**

```typescript
// frontend/src/lib/room/themes/starry-night.ts
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
```

- [ ] **Step 4: Create forest-green.ts (shop 200⚡)**

```typescript
// frontend/src/lib/room/themes/forest-green.ts
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
```

- [ ] **Step 5: Create ancient-study.ts (achievement unlock)**

```typescript
// frontend/src/lib/room/themes/ancient-study.ts
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
```

- [ ] **Step 6: Create crystal-hall.ts (shop 500⚡)**

```typescript
// frontend/src/lib/room/themes/crystal-hall.ts
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
```

- [ ] **Step 7: Create ocean-deep.ts (gacha rare)**

```typescript
// frontend/src/lib/room/themes/ocean-deep.ts
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
```

- [ ] **Step 8: Create registry.ts**

```typescript
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
```

- [ ] **Step 9: Verify svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -5
```
Expected: 0 errors

---

### Task 5: Backend — room_theme_def Table + Entity + Mapper + Seed Data

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `backend/src/main/resources/data.sql`
- Create: `backend/src/main/java/com/petgrowup/room/entity/RoomThemeDef.java`
- Create: `backend/src/main/java/com/petgrowup/room/mapper/RoomThemeDefMapper.java`

**Interfaces:**
- Produces: `RoomThemeDef` entity, `RoomThemeDefMapper`, DB table with 6 themes seeded

- [ ] **Step 1: Add room_theme_def table to schema.sql**

Insert before `CREATE TABLE IF NOT EXISTS pet_room` (around line 412):
```sql
-- Pet Room Theme Definitions
CREATE TABLE IF NOT EXISTS room_theme_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    theme_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    icon_url VARCHAR(255),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

- [ ] **Step 2: Create RoomThemeDef.java entity**

```java
// backend/src/main/java/com/petgrowup/room/entity/RoomThemeDef.java
package com.petgrowup.room.entity;

import com.mybatisflex.annotation.Column;
import com.mybatisflex.annotation.Id;
import com.mybatisflex.annotation.KeyType;
import com.mybatisflex.annotation.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table("room_theme_def")
public class RoomThemeDef {

    @Id(keyType = KeyType.Auto)
    private Long id;

    @Column("theme_key")
    private String themeKey;

    @Column("name")
    private String name;

    @Column("description")
    private String description;

    @Column("icon_url")
    private String iconUrl;

    @Column("is_default")
    private Boolean isDefault;

    @Column("sort_order")
    private Integer sortOrder;

    @Column(value = "created_at", onInsertValue = "NOW()")
    private LocalDateTime createdAt;
}
```

- [ ] **Step 3: Create RoomThemeDefMapper.java**

```java
// backend/src/main/java/com/petgrowup/room/mapper/RoomThemeDefMapper.java
package com.petgrowup.room.mapper;

import com.mybatisflex.core.BaseMapper;
import com.petgrowup.room.entity.RoomThemeDef;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RoomThemeDefMapper extends BaseMapper<RoomThemeDef> {
}
```

- [ ] **Step 4: Add theme + ROOM_THEME item_def seed data to data.sql**

Append to data.sql:
```sql
-- Room theme definitions
INSERT IGNORE INTO room_theme_def (theme_key, name, description, icon_url, is_default, sort_order) VALUES
('cozy_warm', '温馨暖居', '温暖舒适的默认小屋，每个小精灵最初的港湾', '🏠', TRUE, 1),
('starry_night', '星空夜语', '深蓝夜空下繁星点点，伴你进入梦乡', '🌌', FALSE, 2),
('forest_green', '翠林幽居', '绿意盎然的森林小屋，萤火虫在夜空中舞动', '🌿', FALSE, 3),
('ancient_study', '古风书房', '笔墨纸砚，书香四溢的古雅书房', '📜', FALSE, 4),
('crystal_hall', '水晶殿堂', '晶莹剔透的梦幻宫殿，闪耀着魔法光芒', '💎', FALSE, 5),
('ocean_deep', '深海小屋', '蔚蓝深海中的静谧小屋，与鱼群为伴', '🌊', FALSE, 6);

-- Room theme items (ROOM_THEME category in item_def)
INSERT IGNORE INTO item_def (item_key, name, description, category, sub_category, price_energy, price_points, icon_url, is_consumable, is_shop_available, sort_order) VALUES
('theme_starry_night', '星空小屋主题', '解锁星空夜语房间主题（可随时切换）', 'ROOM_THEME', NULL, 200, 0, '🌌', FALSE, TRUE, 90),
('theme_forest_green', '森林小屋主题', '解锁翠林幽居房间主题（可随时切换）', 'ROOM_THEME', NULL, 200, 0, '🌿', FALSE, TRUE, 91),
('theme_crystal_hall', '水晶殿堂主题', '解锁水晶殿堂房间主题（可随时切换）', 'ROOM_THEME', NULL, 500, 0, '💎', FALSE, TRUE, 92),
('theme_ancient_study', '古风书房主题', '解锁古风书房房间主题（成就奖励）', 'ROOM_THEME', NULL, 0, 0, '📜', FALSE, FALSE, 93),
('theme_ocean_deep', '深海小屋主题', '解锁深海小屋房间主题（扭蛋限定）', 'ROOM_THEME', NULL, 0, 0, '🌊', FALSE, FALSE, 94);
```

- [ ] **Step 5: Verify mvn compile**

```bash
cd /home/fxb_2/Codes/pet-grow-up/backend && mvn compile -q 2>&1 | tail -5
```
Expected: BUILD SUCCESS

---

### Task 6: Backend — Slot Data Migration + Theme Service + Controller Update

**Files:**
- Modify: `backend/src/main/java/com/petgrowup/room/dto/PetRoomDTO.java`
- Modify: `backend/src/main/java/com/petgrowup/room/dto/PlaceItemRequest.java`
- Create: `backend/src/main/java/com/petgrowup/room/dto/UpdatePositionRequest.java`
- Create: `backend/src/main/java/com/petgrowup/room/dto/ChangeThemeRequest.java`
- Modify: `backend/src/main/java/com/petgrowup/room/service/PetRoomService.java`
- Modify: `backend/src/main/java/com/petgrowup/room/controller/PetRoomController.java`

**Interfaces:**
- Consumes: `RoomThemeDefMapper` from Task 5
- Produces: Free-form furniture placement, theme switching, position update endpoints

- [ ] **Step 1: Update PlaceItemRequest.java for free-form coordinates**

```java
// backend/src/main/java/com/petgrowup/room/dto/PlaceItemRequest.java
package com.petgrowup.room.dto;

import lombok.Data;

@Data
public class PlaceItemRequest {
    private Long userItemId;
    private Double x;       // position x in room (0-400)
    private Double y;       // position y in room (0-300)
}
```

- [ ] **Step 2: Create UpdatePositionRequest.java**

```java
// backend/src/main/java/com/petgrowup/room/dto/UpdatePositionRequest.java
package com.petgrowup.room.dto;

import lombok.Data;

@Data
public class UpdatePositionRequest {
    private Long userItemId;
    private Double x;
    private Double y;
}
```

- [ ] **Step 3: Create ChangeThemeRequest.java**

```java
// backend/src/main/java/com/petgrowup/room/dto/ChangeThemeRequest.java
package com.petgrowup.room.dto;

import lombok.Data;

@Data
public class ChangeThemeRequest {
    private String themeKey;
}
```

- [ ] **Step 4: Update PetRoomDTO.java — change placedItems from Map to List with positions**

```java
// backend/src/main/java/com/petgrowup/room/dto/PetRoomDTO.java
package com.petgrowup.room.dto;

import com.petgrowup.spirit.dto.SpiritDTO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class PetRoomDTO {
    private Long id;
    private String roomStyle;       // theme key now
    private String themeName;       // resolved from theme def
    private String themeIcon;       // for UI display
    private List<PlacedItemDTO> furniture;  // free-form furniture list
    private SpiritDTO activeSpirit;

    @Data
    @Builder
    @AllArgsConstructor
    public static class PlacedItemDTO {
        private Long itemDefId;
        private Long userItemId;
        private String itemKey;
        private String name;
        private String iconUrl;
        private String category;
        private Double x;           // position in room SVG
        private Double y;
    }
}
```

- [ ] **Step 5: Update PetRoomService.java — free-form placement + theme + position update**

The `slot_data` JSON format changes from `{"slot_key": item_def_id}` to:
```json
[{"userItemId": 1, "itemDefId": 60, "itemKey": "deco_bed_small", "x": 100.0, "y": 200.0}]
```

Add to the service class — inject RoomThemeDefMapper:
```java
private final RoomThemeDefMapper roomThemeDefMapper;

public PetRoomService(PetRoomMapper petRoomMapper, UserMapper userMapper,
                      UserItemMapper userItemMapper, ItemDefMapper itemDefMapper,
                      SpiritService spiritService, RoomThemeDefMapper roomThemeDefMapper) {
    // ... existing assignments ...
    this.roomThemeDefMapper = roomThemeDefMapper;
}
```

Update `parseSlotData` — change return type and parsing logic:
```java
private List<Map<String, Object>> parseSlotData(String json) {
    if (json == null || json.isBlank()) return new ArrayList<>();
    try {
        // Try new format first: [{"userItemId":..., "itemDefId":..., ...}]
        if (json.trim().startsWith("[")) {
            return objectMapper.readValue(json, new TypeReference<List<Map<String, Object>>>() {});
        }
        // Legacy format: {"slot_key": itemDefId} — migrate to empty list
        return new ArrayList<>();
    } catch (JsonProcessingException e) {
        return new ArrayList<>();
    }
}

private String toJson(List<Map<String, Object>> list) {
    try {
        return objectMapper.writeValueAsString(list);
    } catch (JsonProcessingException e) {
        return "[]";
    }
}
```

Update `getRoom` — resolve theme name from RoomThemeDef, build furniture from slot data list:
```java
public PetRoomDTO getRoom(Long userId) {
    User user = userMapper.selectOneById(userId);
    if (user == null) throw new BusinessException("用户不存在");

    PetRoom room = findOrCreateRoom(userId);
    List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());

    // Resolve theme info
    RoomThemeDef theme = roomThemeDefMapper.selectOneByQuery(
            QueryWrapper.create().eq("theme_key", room.getRoomStyle()));
    String themeName = theme != null ? theme.getName() : "温馨暖居";
    String themeIcon = theme != null ? theme.getIconUrl() : "🏠";

    // Build furniture list
    List<PlacedItemDTO> furniture = new ArrayList<>();
    for (Map<String, Object> entry : slotList) {
        Number itemDefIdNum = (Number) entry.get("itemDefId");
        if (itemDefIdNum == null) continue;
        ItemDef item = itemDefMapper.selectOneById(itemDefIdNum.longValue());
        if (item != null) {
            Number x = (Number) entry.getOrDefault("x", 200.0);
            Number y = (Number) entry.getOrDefault("y", 220.0);
            Number userItemId = (Number) entry.get("userItemId");
            furniture.add(PlacedItemDTO.builder()
                    .itemDefId(item.getId())
                    .userItemId(userItemId != null ? userItemId.longValue() : null)
                    .itemKey(item.getItemKey())
                    .name(item.getName())
                    .iconUrl(item.getIconUrl())
                    .category(item.getCategory())
                    .x(x.doubleValue())
                    .y(y.doubleValue())
                    .build());
        }
    }

    return PetRoomDTO.builder()
            .id(room.getId())
            .roomStyle(room.getRoomStyle())
            .themeName(themeName)
            .themeIcon(themeIcon)
            .furniture(furniture)
            .activeSpirit(user.getCurrentSpiritId() != null
                    ? spiritService.getSpiritDetail(user.getCurrentSpiritId()) : null)
            .build();
}
```

Update `placeItem` — accept x,y and store in new JSON format:
```java
@Transactional
public PetRoomDTO placeItem(Long userId, PlaceItemRequest req) {
    UserItem userItem = userItemMapper.selectOneById(req.getUserItemId());
    if (userItem == null || !userItem.getUserId().equals(userId))
        throw new BusinessException("物品不存在或不属于你");
    ItemDef item = itemDefMapper.selectOneById(userItem.getItemDefId());
    if (item == null || !"DECORATION".equals(item.getCategory()))
        throw new BusinessException("该物品不是装饰品");
    if (userItem.getQuantity() <= 0)
        throw new BusinessException("物品数量不足");

    PetRoom room = findOrCreateRoom(userId);
    List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());

    // Add new furniture entry
    Map<String, Object> entry = new LinkedHashMap<>();
    entry.put("userItemId", req.getUserItemId());
    entry.put("itemDefId", item.getId());
    entry.put("itemKey", item.getItemKey());
    entry.put("x", req.getX() != null ? req.getX() : 200.0);
    entry.put("y", req.getY() != null ? req.getY() : 220.0);
    slotList.add(entry);

    room.setSlotData(toJson(slotList));
    petRoomMapper.update(room);

    return getRoom(userId);
}
```

Update `removeItem` — remove by userItemId from the list, not by slotKey:
```java
@Transactional
public PetRoomDTO removeItem(Long userId, Long userItemId) {
    PetRoom room = petRoomMapper.selectOneByQuery(
            QueryWrapper.create().eq("user_id", userId));
    if (room == null) return getRoom(userId);

    List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());
    slotList.removeIf(entry -> {
        Number uid = (Number) entry.get("userItemId");
        return uid != null && uid.longValue() == userItemId;
    });

    room.setSlotData(toJson(slotList));
    petRoomMapper.update(room);

    return getRoom(userId);
}
```

Add `updatePosition` method:
```java
@Transactional
public PetRoomDTO updatePosition(Long userId, UpdatePositionRequest req) {
    PetRoom room = petRoomMapper.selectOneByQuery(
            QueryWrapper.create().eq("user_id", userId));
    if (room == null) throw new BusinessException("房间不存在");

    List<Map<String, Object>> slotList = parseSlotData(room.getSlotData());
    for (Map<String, Object> entry : slotList) {
        Number uid = (Number) entry.get("userItemId");
        if (uid != null && uid.longValue() == req.getUserItemId()) {
            entry.put("x", req.getX());
            entry.put("y", req.getY());
            break;
        }
    }

    room.setSlotData(toJson(slotList));
    petRoomMapper.update(room);

    return getRoom(userId);
}
```

Add `changeTheme` method:
```java
@Transactional
public PetRoomDTO changeTheme(Long userId, String themeKey) {
    // Verify theme exists
    RoomThemeDef theme = roomThemeDefMapper.selectOneByQuery(
            QueryWrapper.create().eq("theme_key", themeKey));
    if (theme == null) throw new BusinessException("主题不存在");

    PetRoom room = findOrCreateRoom(userId);
    room.setRoomStyle(themeKey);
    petRoomMapper.update(room);

    return getRoom(userId);
}
```

Also update `getAvailableDecorations` — keep same logic (filter by DECORATION), no change needed.

- [ ] **Step 6: Update PetRoomController.java — new endpoints + changed signatures**

```java
// backend/src/main/java/com/petgrowup/room/controller/PetRoomController.java
package com.petgrowup.room.controller;

import com.petgrowup.common.response.ApiResponse;
import com.petgrowup.room.dto.*;
import com.petgrowup.room.dto.PetRoomDTO.PlacedItemDTO;
import com.petgrowup.room.service.PetRoomService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/pet-room")
public class PetRoomController {

    private final PetRoomService petRoomService;

    public PetRoomController(PetRoomService petRoomService) {
        this.petRoomService = petRoomService;
    }

    @GetMapping
    public ApiResponse<PetRoomDTO> getRoom(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(petRoomService.getRoom(userId));
    }

    @PostMapping("/place")
    public ApiResponse<PetRoomDTO> placeItem(@AuthenticationPrincipal Long userId,
                                              @RequestBody PlaceItemRequest request) {
        return ApiResponse.success(petRoomService.placeItem(userId, request));
    }

    @DeleteMapping("/remove")
    public ApiResponse<PetRoomDTO> removeItem(@AuthenticationPrincipal Long userId,
                                               @RequestParam Long userItemId) {
        return ApiResponse.success(petRoomService.removeItem(userId, userItemId));
    }

    @PutMapping("/position")
    public ApiResponse<PetRoomDTO> updatePosition(@AuthenticationPrincipal Long userId,
                                                   @RequestBody UpdatePositionRequest request) {
        return ApiResponse.success(petRoomService.updatePosition(userId, request));
    }

    @PutMapping("/theme")
    public ApiResponse<PetRoomDTO> changeTheme(@AuthenticationPrincipal Long userId,
                                                @RequestBody ChangeThemeRequest request) {
        return ApiResponse.success(petRoomService.changeTheme(userId, request.getThemeKey()));
    }

    @GetMapping("/available-decorations")
    public ApiResponse<List<PlacedItemDTO>> getAvailableDecorations(@AuthenticationPrincipal Long userId) {
        return ApiResponse.success(petRoomService.getAvailableDecorations(userId));
    }
}
```

- [ ] **Step 7: Verify mvn compile**

```bash
cd /home/fxb_2/Codes/pet-grow-up/backend && mvn compile -q 2>&1 | tail -10
```
Expected: BUILD SUCCESS

---

### Task 7: Frontend API Update (pet-room.ts)

**Files:**
- Modify: `frontend/src/lib/api/pet-room.ts`

**Interfaces:**
- Consumes: Backend DTO changes from Task 6
- Produces: Updated TypeScript types and API functions

- [ ] **Step 1: Rewrite pet-room.ts**

```typescript
// frontend/src/lib/api/pet-room.ts
import { api } from './client';
import type { SpiritDTO } from '$lib/types/api';

export interface PlacedItem {
  itemDefId: number;
  userItemId?: number;
  itemKey: string;
  name: string;
  iconUrl: string;
  category: string;
  x: number;          // position in room (0-400)
  y: number;          // position in room (0-300)
}

export interface PetRoomData {
  id: number;
  roomStyle: string;       // theme key e.g. 'cozy_warm'
  themeName: string;       // resolved theme display name
  themeIcon: string;       // theme emoji icon
  furniture: PlacedItem[]; // free-form furniture list (was placedItems)
  activeSpirit: SpiritDTO | null;
}

export function getPetRoom(): Promise<PetRoomData> {
  return api.get<PetRoomData>('/pet-room');
}

export function placeItem(userItemId: number, x: number, y: number): Promise<PetRoomData> {
  return api.post<PetRoomData>('/pet-room/place', { userItemId, x, y });
}

export function removeItem(userItemId: number): Promise<PetRoomData> {
  return api.delete<PetRoomData>(`/pet-room/remove?userItemId=${userItemId}`);
}

export function updatePosition(userItemId: number, x: number, y: number): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/position', { userItemId, x, y });
}

export function changeTheme(themeKey: string): Promise<PetRoomData> {
  return api.put<PetRoomData>('/pet-room/theme', { themeKey });
}

export function getAvailableDecorations(): Promise<PlacedItem[]> {
  return api.get<PlacedItem[]>('/pet-room/available-decorations');
}
```

- [ ] **Step 2: Verify svelte-check (will fail until Task 8 updates consumers)**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -10
```

Ignore type errors about missing exports until Task 8 — existing consumers (`+page.svelte`, `PetRoomScene.svelte`, `DecorationPicker.svelte`) will be updated in Tasks 8-9.

---

### Task 8: PetRoomScene Rewrite

**Files:**
- Modify: `frontend/src/lib/components/room/PetRoomScene.svelte` (complete rewrite)

**Interfaces:**
- Consumes: `getTheme` from Task 4, `getFurnitureRenderer` from Task 3, `PetRoomData` from Task 7
- Produces: Full multi-layer SVG room with theme, furniture, spirit, ambient particles

- [ ] **Step 1: Rewrite PetRoomScene.svelte**

```svelte
<script lang="ts">
  import type { PetRoomData, PlacedItem } from '$lib/api/pet-room';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { getTheme, defaultTheme } from '$lib/room/themes/registry';
  import type { RoomTheme } from '$lib/room/themes/types';
  import { getFurnitureRenderer } from '$lib/room/furniture/registry';
  import type { FurnitureContext } from '$lib/room/furniture/types';

  let {
    room,
    editing = false,
    selectedItemId = null as number | null,
    accessories = [] as { slot: string; iconUrl: string; name: string }[],
    onfurnitureclick,
    onfurnituredragend,
  }: {
    room: PetRoomData;
    editing?: boolean;
    selectedItemId?: number | null;
    accessories?: { slot: string; iconUrl: string; name: string }[];
    onfurnitureclick?: (item: PlacedItem) => void;
    onfurnituredragend?: (item: PlacedItem, x: number, y: number) => void;
  } = $props();

  let theme = $derived(getTheme(room.roomStyle));
  let furniture = $derived(room.furniture || []);

  // Split furniture into back (wall) and front (floor) by y-position
  let floorY = $derived(200);
  let backFurniture = $derived(furniture.filter(f => (f.y ?? 220) < floorY));
  let frontFurniture = $derived(furniture.filter(f => (f.y ?? 220) >= floorY));

  // Sort front furniture by y (lower y = further back = render first)
  let sortedFront = $derived([...frontFurniture].sort((a, b) => (a.y ?? 220) - (b.y ?? 220)));

  let spiritMood = $derived.by((): 'idle' | 'happy' | 'excited' | 'hurt' => {
    if (!room.activeSpirit) return 'idle';
    const s = room.activeSpirit;
    if (s.happiness >= 80) return 'excited';
    if (s.happiness >= 50) return 'happy';
    return 'idle';
  });

  // Drag state
  let dragging = $state<number | null>(null);
  let dragOffsetX = $state(0);
  let dragOffsetY = $state(0);

  function handlePointerDown(e: PointerEvent, item: PlacedItem) {
    if (!editing) return;
    dragging = item.userItemId ?? item.itemDefId;
    const svg = (e.currentTarget as SVGElement).closest('svg')!;
    const rect = svg.getBoundingClientRect();
    const svgX = ((e.clientX - rect.left) / rect.width) * 400;
    const svgY = ((e.clientY - rect.top) / rect.height) * 300;
    dragOffsetX = svgX - (item.x ?? 200);
    dragOffsetY = svgY - (item.y ?? 220);
    (e.currentTarget as SVGElement).setPointerCapture(e.pointerId);
  }

  function handlePointerMove(e: PointerEvent) {
    if (dragging === null) return;
    // Visual feedback: we update dragOffset to track movement
    const svg = (e.currentTarget as SVGElement).closest('svg')!;
    const rect = svg.getBoundingClientRect();
    const svgX = ((e.clientX - rect.left) / rect.width) * 400;
    const svgY = ((e.clientY - rect.top) / rect.height) * 300;
    dragOffsetX = svgX - ((furniture.find(f => (f.userItemId ?? f.itemDefId) === dragging)?.x) ?? 200);
    dragOffsetY = svgY - ((furniture.find(f => (f.userItemId ?? f.itemDefId) === dragging)?.y) ?? 220);
  }

  function handlePointerUp(e: PointerEvent) {
    if (dragging === null) return;
    const item = furniture.find(f => (f.userItemId ?? f.itemDefId) === dragging);
    if (item) {
      const svg = (e.currentTarget as SVGElement).closest('svg')!;
      const rect = svg.getBoundingClientRect();
      const newX = Math.max(20, Math.min(380, ((e.clientX - rect.left) / rect.width) * 400));
      const newY = Math.max(30, Math.min(280, ((e.clientY - rect.top) / rect.height) * 300));
      onfurnituredragend?.(item, Math.round(newX), Math.round(newY));
    }
    dragging = null;
    (e.currentTarget as SVGElement).releasePointerCapture(e.pointerId);
  }

  function renderFurniture(item: PlacedItem): string {
    const renderer = getFurnitureRenderer(item.itemKey);
    if (!renderer) {
      // Fallback: emoji text
      const x = item.x ?? 200;
      const y = item.y ?? 220;
      return `<text x="${x}" y="${y}" font-size="24" text-anchor="middle" dominant-baseline="central">${item.iconUrl || '📦'}</text>`;
    }
    const ctx: FurnitureContext = {
      x: item.x ?? 200,
      y: item.y ?? 220,
      scale: 1.0,
      floorY: 200,
    };
    return renderer(ctx);
  }

  // Theme-driven ambient particles
  function renderParticles(theme: RoomTheme): string {
    switch (theme.ambientParticles) {
      case 'stars': {
        let s = '';
        for (let i = 0; i < 12; i++) {
          const px = 20 + Math.random() * 360;
          const py = 10 + Math.random() * 100;
          const r = 0.5 + Math.random() * 1.5;
          const delay = Math.random() * 3;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="#fbbf24" opacity="0.6">
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + Math.random() * 2}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'fireflies': {
        let s = '';
        for (let i = 0; i < 6; i++) {
          const px = 50 + Math.random() * 300;
          const py = 30 + Math.random() * 170;
          const delay = Math.random() * 4;
          s += `<circle cx="${px}" cy="${py}" r="2" fill="#fbbf24" opacity="0.7">
            <animate attributeName="cx" values="${px - 10};${px + 10};${px - 10}" dur="${4 + Math.random() * 3}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + Math.random() * 2}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'petals': {
        let s = '';
        for (let i = 0; i < 8; i++) {
          const px = 20 + Math.random() * 360;
          const py = 20 + Math.random() * 80;
          const delay = Math.random() * 5;
          s += `<text x="${px}" y="${py}" font-size="6" fill="#f472b6" opacity="0.5">
            🌸
            <animate attributeName="y" values="${py};${py + 200}" dur="${6 + Math.random() * 4}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.5;0.2;0" dur="${6 + Math.random() * 4}s" begin="${delay}s" repeatCount="indefinite"/>
          </text>`;
        }
        return s;
      }
      case 'sparkles': {
        let s = '';
        for (let i = 0; i < 10; i++) {
          const px = 30 + Math.random() * 340;
          const py = 10 + Math.random() * 100;
          const delay = Math.random() * 2;
          s += `<polygon points="${px},${py - 3} ${px + 2},${py} ${px},${py + 3} ${px - 2},${py}"
            fill="#a78bfa" opacity="0.6">
            <animate attributeName="opacity" values="0;0.8;0" dur="${1.5 + Math.random() * 1.5}s" begin="${delay}s" repeatCount="indefinite"/>
          </polygon>`;
        }
        return s;
      }
      case 'bubbles': {
        let s = '';
        for (let i = 0; i < 5; i++) {
          const px = 50 + Math.random() * 300;
          const py = 100 + Math.random() * 100;
          const r = 3 + Math.random() * 5;
          const delay = Math.random() * 4;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="none" stroke="#7dd3fc" stroke-width="0.8" opacity="0.4">
            <animate attributeName="cy" values="${py};${py - 160}" dur="${5 + Math.random() * 3}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.4;0.1;0" dur="${5 + Math.random() * 3}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      default: return '';
    }
  }
</script>

<div class="relative w-full max-w-lg mx-auto">
  <svg viewBox="0 0 400 300" class="w-full rounded-2xl shadow-lg border"
       style="border-color: {theme.colorScheme.primary}33;"
       onpointermove={editing ? handlePointerMove : undefined}
       onpointerup={editing ? handlePointerUp : undefined}>

    <!-- Layer -2: Wall -->
    <defs>
      <linearGradient id="wallGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.wall.gradient[0]}/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]}/>
      </linearGradient>
      <linearGradient id="floorGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.floor.color}/>
        <stop offset="100%" stop-color={theme.floor.plankColor}/>
      </linearGradient>
      <radialGradient id="lampGlow" cx="50%" cy="0%" r="60%">
        <stop offset="0%" stop-color={theme.lamp.glowColor} stop-opacity="0.6"/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]} stop-opacity="0"/>
      </radialGradient>
    </defs>

    <!-- Wall -->
    <rect x="0" y="0" width="400" height="200" fill="url(#wallGrad)"/>
    <!-- Lamp glow overlay -->
    <ellipse cx="200" cy="0" rx="180" ry="100" fill="url(#lampGlow)"/>

    <!-- Layer -1: Ambient particles -->
    {@html renderParticles(theme)}

    <!-- Layer -1: Window + Default lamp -->
    {#if theme.window.style === 'porthole'}
      <circle cx="200" cy="75" r="30" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="3"/>
      <circle cx="200" cy="75" r="27" fill="none" stroke={theme.window.frameColor} stroke-width="1" opacity="0.5"/>
    {:else if theme.window.style === 'round'}
      <circle cx="200" cy="75" r="35" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
      <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="1.5"/>
      <line x1="165" y1="75" x2="235" y2="75" stroke={theme.window.frameColor} stroke-width="1.5"/>
    {:else if theme.window.style === 'square'}
      <rect x="145" y="40" width="110" height="80" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5" rx="2"/>
      <line x1="200" y1="40" x2="200" y2="120" stroke={theme.window.frameColor} stroke-width="1.5"/>
      <line x1="145" y1="80" x2="255" y2="80" stroke={theme.window.frameColor} stroke-width="1.5"/>
    {:else}
      <!-- Default arched window -->
      <path d="M155,110 L155,50 Q155,40 165,40 L235,40 Q245,40 245,50 L245,110 Z"
            fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
      <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="2"/>
      <line x1="155" y1="75" x2="245" y2="75" stroke={theme.window.frameColor} stroke-width="2"/>
    {/if}

    <!-- Ceiling lamp -->
    {#if theme.lamp.style === 'lantern'}
      <line x1="200" y1="0" x2="200" y2="15" stroke="#713f12" stroke-width="1.5"/>
      <rect x="188" y="15" width="24" height="20" rx="3" fill="#dc2626" opacity="0.8"/>
      <ellipse cx="200" cy="25" rx="12" ry="4" fill="#fbbf24" opacity="0.2"/>
    {:else if theme.lamp.style === 'crystal'}
      <line x1="200" y1="0" x2="200" y2="12" stroke="#c4b5fd" stroke-width="1"/>
      <polygon points="188,12 212,12 206,22 194,22" fill="#a78bfa" opacity="0.7"/>
      <polygon points="190,22 210,22 204,30 196,30" fill="#c4b5fd" opacity="0.5"/>
      <circle cx="200" cy="26" r="4" fill="#e0e7ff" opacity="0.6"/>
    {:else if theme.lamp.style === 'mushroom'}
      <line x1="200" y1="0" x2="200" y2="14" stroke="#78716c" stroke-width="1.5"/>
      <ellipse cx="200" cy="18" rx="14" ry="8" fill="#eab308" opacity="0.7"/>
      <circle cx="194" cy="17" r="2" fill="#fef9c3" opacity="0.5"/>
      <circle cx="206" cy="18" r="1.5" fill="#fef9c3" opacity="0.4"/>
    {:else if theme.lamp.style === 'shell'}
      <line x1="200" y1="0" x2="200" y2="14" stroke="#475569" stroke-width="1"/>
      <path d="M185,14 Q200,8 215,14 Q200,28 185,14 Z" fill="#fbbf24" opacity="0.5"/>
      <ellipse cx="200" cy="18" rx="10" ry="6" fill="#fef3c7" opacity="0.3"/>
    {:else}
      <!-- Default pendant -->
      <line x1="200" y1="0" x2="200" y2="20" stroke={theme.lamp.bodyColor} stroke-width="1.5"/>
      <circle cx="200" cy="22" r="6" fill={theme.lamp.glowColor} stroke={theme.lamp.bodyColor} stroke-width="1"/>
      <circle cx="200" cy="22" r="3" fill="#fff8e1" opacity="0.8"/>
    {/if}

    <!-- Layer 0: Floor -->
    <rect x="0" y="200" width="400" height="100" fill="url(#floorGrad)"/>
    <line x1="0" y1="220" x2="400" y2="220" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <line x1="0" y1="245" x2="400" y2="245" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <line x1="0" y1="270" x2="400" y2="270" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>

    <!-- Baseboard -->
    <rect x="0" y="197" width="400" height="3" fill={theme.floor.baseboardColor}/>

    <!-- Default rug -->
    <ellipse cx="200" cy="250" rx="50" ry="12" fill={theme.defaultRug.color} opacity={theme.defaultRug.opacity}/>

    <!-- Layer 1: Back furniture (wall-mounted, y < floorY) -->
    {#each backFurniture as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-grab' : ''}
         class:active={editing && (item.userItemId ?? item.itemDefId) === dragging}
         onpointerdown={editing ? (e: PointerEvent) => handlePointerDown(e, item) : undefined}
         onclick={() => editing && onfurnitureclick?.(item)}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId}
          <rect x={(item.x ?? 200) - 22} y={(item.y ?? 80) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Layer 2: Spirit (center) -->
    {#if room.activeSpirit}
      <g transform="translate(200, 178)">
        <foreignObject x="-50" y="-80" width="100" height="100">
          <div style="width:100px;height:100px;display:flex;align-items:center;justify-content:center;">
            <SpiritAvatar
              species={room.activeSpirit.species}
              evolutionStage={room.activeSpirit.currentEvolutionStage}
              size="lg"
              mood={spiritMood}
              {accessories}
            />
          </div>
        </foreignObject>
      </g>
    {:else}
      <text x="200" y="160" font-size="40" text-anchor="middle" opacity="0.2">🐣</text>
    {/if}

    <!-- Layer 3: Front furniture (floor, y >= floorY, sorted by y) -->
    {#each sortedFront as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-grab' : ''}
         class:active={editing && (item.userItemId ?? item.itemDefId) === dragging}
         onpointerdown={editing ? (e: PointerEvent) => handlePointerDown(e, item) : undefined}
         onclick={() => editing && onfurnitureclick?.(item)}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId}
          <rect x={(item.x ?? 200) - 22} y={(item.y ?? 220) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Room label -->
    <text x="15" y="288" font-size="9" fill={theme.floor.plankColor} font-family="sans-serif">
      {theme.icon} {room.activeSpirit ? room.activeSpirit.nickname + '的小屋' : '温馨小屋'} · {theme.name}
    </text>
  </svg>
</div>

<style>
  .cursor-grab { cursor: grab; }
  .cursor-grab:active { cursor: grabbing; }
</style>
```

- [ ] **Step 2: Verify svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -10
```

Expect errors related to `+page.svelte` consumers (updated in Task 9). PetRoomScene itself should be clean.

---

**⚠️ Correction to Task 8 Step 1:** The code block above uses `foreignObject` to embed SpiritAvatar inside the SVG. This is broken — SpiritAvatar renders its own `<svg>`, and browsers don't render nested SVGs inside `foreignObject`. The spirit MUST stay outside the room SVG, positioned with absolute CSS (`position: absolute; left: 50%; bottom: 22%; transform: translateX(-50%)`), exactly as the current working implementation does. The SVG renders: wall → particles → window/lamp → floor → back furniture → front furniture. The spirit div overlays on top with absolute positioning. All furniture occlusion happens within the SVG between furniture items (sorted by y-position). Proper spirit-furniture front/back occlusion is deferred to Layer 2.

### Task 9: pet-room Page Update + Decoration Picker

**Files:**
- Modify: `frontend/src/routes/app/pet-room/+page.svelte`
- Modify: `frontend/src/lib/components/room/DecorationPicker.svelte`

**Interfaces:**
- Consumes: Updated `PetRoomData`, `PlacedItem`, `placeItem`, `removeItem`, `changeTheme` from Task 7
- Produces: Working room page with theme switching, free-form placement, decoration picker

- [ ] **Step 1: Rewrite +page.svelte**

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { getPetRoom, placeItem, removeItem, changeTheme, getAvailableDecorations, type PetRoomData, type PlacedItem } from '$lib/api/pet-room';
  import { getEquippedAccessories, type AccessoryDTO } from '$lib/api/spirit';
  import { getAllThemes, defaultTheme } from '$lib/room/themes/registry';
  import PetRoomScene from '$lib/components/room/PetRoomScene.svelte';
  import DecorationPicker from '$lib/components/room/DecorationPicker.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';

  let room = $state<PetRoomData | null>(null);
  let decorations = $state<PlacedItem[]>([]);
  let spiritAccessories = $state<AccessoryDTO[]>([]);
  let loading = $state(true);
  let editing = $state(false);
  let selectedItemId = $state<number | null>(null);
  let showThemePicker = $state(false);
  let showDecorationPicker = $state(false);
  let placementX = $state(200);
  let placementY = $state(220);

  let themes = $derived(getAllThemes());

  onMount(async () => {
    await loadRoom();
    await loadDecorations();
    loading = false;
  });

  $effect(() => {
    if (room?.activeSpirit?.id) {
      getEquippedAccessories(room.activeSpirit.id)
        .then(a => spiritAccessories = a)
        .catch(() => spiritAccessories = []);
    }
  });

  async function loadRoom() {
    try { room = await getPetRoom(); } catch { room = null; }
  }

  async function loadDecorations() {
    try { decorations = await getAvailableDecorations(); } catch { decorations = []; }
  }

  function handleFurnitureClick(item: PlacedItem) {
    if (!editing) return;
    const id = item.userItemId ?? item.itemDefId;
    if (selectedItemId === id) {
      // Second click: remove
      handleRemove(item);
    } else {
      selectedItemId = id;
    }
  }

  function handleAddDecoration() {
    showDecorationPicker = true;
    // Default placement: center of room on the floor
    placementX = 180 + Math.random() * 40;
    placementY = 210 + Math.random() * 30;
  }

  async function handleSelectDecoration(item: PlacedItem) {
    showDecorationPicker = false;
    try {
      room = await placeItem(item.userItemId ?? item.itemDefId, placementX, placementY);
      selectedItemId = null;
      await loadDecorations();
      toastStore.success(`已放置 ${item.name}`);
    } catch (e: any) { toastStore.error(e.message || '放置失败'); }
  }

  async function handleRemove(item: PlacedItem) {
    if (!room) return;
    const id = item.userItemId ?? item.itemDefId;
    try {
      room = await removeItem(id);
      selectedItemId = null;
      await loadDecorations();
      toastStore.success('已移除装饰品');
    } catch (e: any) { toastStore.error(e.message || '移除失败'); }
  }

  async function handleChangeTheme(themeKey: string) {
    try {
      room = await changeTheme(themeKey);
      showThemePicker = false;
      toastStore.success('主题已切换');
    } catch (e: any) { toastStore.error(e.message || '切换失败'); }
  }
</script>

<svelte:head>
  <title>精灵小屋 - Pet Grow Up</title>
</svelte:head>

<div class="max-w-2xl mx-auto animate-slide-up">
  <div class="bg-white rounded-2xl shadow-sm p-6 border border-gray-100">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{room?.themeIcon || '🏠'} 精灵小屋</h1>
        <p class="text-gray-500 text-sm mt-1">
          {editing ? '点击家具选中后可移除，点"+"添加新装饰' : room?.themeName || '温馨小屋'}
        </p>
      </div>
      <div class="flex gap-2">
        <button onclick={() => showThemePicker = !showThemePicker}
                class="px-3 py-2 rounded-lg text-sm font-medium bg-purple-100 text-purple-700 transition">
          🎨 主题
        </button>
        <button onclick={() => { editing = !editing; selectedItemId = null; }}
                class="px-4 py-2 rounded-lg text-sm font-medium transition
                  {editing ? 'bg-green-100 text-green-700' : 'bg-indigo-100 text-indigo-700'}">
          {editing ? '✅ 完成' : '🔧 编辑'}
        </button>
      </div>
    </div>

    <!-- Theme picker -->
    {#if showThemePicker}
      <div class="mb-4 p-3 bg-purple-50 rounded-xl">
        <p class="text-sm text-gray-600 mb-2">选择房间主题（已拥有的主题）</p>
        <div class="grid grid-cols-3 gap-2">
          {#each themes as t}
            <button onclick={() => handleChangeTheme(t.key)}
                    class="p-2 rounded-lg text-sm text-center transition
                      {(room?.roomStyle || defaultTheme.key) === t.key ? 'bg-purple-200 ring-2 ring-purple-400' : 'bg-white hover:bg-purple-100'}">
              <span class="text-xl">{t.icon}</span>
              <span class="block text-xs mt-1">{t.name}</span>
            </button>
          {/each}
        </div>
      </div>
    {/if}

    {#if loading}
      <div class="text-center text-gray-400 py-12">加载中...</div>
    {:else if room}
      <PetRoomScene {room} {editing} {selectedItemId}
        accessories={spiritAccessories}
        onfurnitureclick={handleFurnitureClick} />

      <!-- Add decoration button (editing mode) -->
      {#if editing}
        <div class="mt-3 text-center">
          <button onclick={handleAddDecoration}
                  class="px-4 py-2 rounded-lg text-sm font-medium bg-indigo-500 text-white hover:bg-indigo-600 transition">
            ➕ 添加装饰品
          </button>
          {#if selectedItemId}
            <span class="text-xs text-gray-400 ml-2">已选中家具，再次点击可移除</span>
          {/if}
        </div>
      {/if}

      <!-- Spirit info -->
      {#if room.activeSpirit}
        <div class="mt-4 text-center">
          <p class="text-sm text-gray-500">
            {room.activeSpirit.nickname} · Lv.{room.activeSpirit.currentEvolutionStage}
          </p>
        </div>
      {/if}
    {:else}
      <div class="text-center text-gray-400 py-12">
        <p>还没有精灵？</p>
        <a href="/app/spirit/choose" class="text-indigo-500 hover:text-indigo-600">去选择一只精灵吧 →</a>
      </div>
    {/if}
  </div>

  <!-- Decoration picker modal -->
  <DecorationPicker
    items={decorations}
    show={showDecorationPicker}
    onselect={handleSelectDecoration}
    onclose={() => showDecorationPicker = false}
  />
</div>
```

- [ ] **Step 2: Update DecorationPicker.svelte for new API**

```svelte
<script lang="ts">
  import type { PlacedItem } from '$lib/api/pet-room';

  let {
    items = [],
    show = false,
    onselect,
    onclose,
  }: {
    items: PlacedItem[];
    show?: boolean;
    onselect?: (item: PlacedItem) => void;
    onclose?: () => void;
  } = $props();
</script>

{#if show}
  <div class="fixed inset-0 z-40 flex items-end justify-center bg-black/20"
       role="dialog" onclick={onclose}>
    <div class="bg-white rounded-t-2xl shadow-xl p-5 w-full max-w-md animate-slide-up"
         onclick={(e: Event) => e.stopPropagation()}>
      <div class="flex items-center justify-between mb-3">
        <h3 class="font-semibold text-gray-800">选择装饰品放置</h3>
        <button onclick={onclose} class="text-gray-400 hover:text-gray-600 text-lg">✕</button>
      </div>

      {#if items.length === 0}
        <p class="text-sm text-gray-400 text-center py-8">背包中没有装饰品，去商店购买吧！</p>
      {:else}
        <div class="grid grid-cols-4 gap-3 max-h-64 overflow-y-auto">
          {#each items as item (item.itemKey)}
            <button onclick={() => onselect?.(item)}
                    class="p-3 rounded-xl bg-gray-50 hover:bg-indigo-50 hover:shadow-sm transition text-center">
              <div class="text-2xl mb-1">{item.iconUrl || '📦'}</div>
              <div class="text-xs text-gray-600 truncate">{item.name}</div>
            </button>
          {/each}
        </div>
      {/if}
    </div>
  </div>
{/if}
```

- [ ] **Step 3: Verify svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1 | tail -10
```
Expected: 0 errors

---

### Task 10: Final Verification

- [ ] **Step 1: Run svelte-check**

```bash
cd /home/fxb_2/Codes/pet-grow-up/frontend && npx svelte-check --tsconfig ./tsconfig.json 2>&1
```
Expected: 0 errors

- [ ] **Step 2: Run mvn compile**

```bash
cd /home/fxb_2/Codes/pet-grow-up/backend && mvn compile 2>&1 | tail -5
```
Expected: BUILD SUCCESS

- [ ] **Step 3: Manual verification checklist**
  - Spirit with hat/scarf/glasses: accessories are proper SVG shapes on the spirit body (not emojis)
  - Room shows themed wall/floor/window/lamp matching selected theme
  - Furniture rendered as SVG shapes with drop shadows (not emoji text)
  - Theme switcher shows 6 themes, switching updates room immediately
  - "Add decoration" opens picker, selecting places furniture at default position
  - Editing mode: clicking furniture selects it, clicking again removes it
  - Room data persists on reload

---
