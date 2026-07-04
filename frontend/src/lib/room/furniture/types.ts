// frontend/src/lib/room/furniture/types.ts

export interface FurnitureContext {
  x: number;              // center x in room SVG (0-400)
  y: number;              // center y in room SVG (0-300)
  scale: number;          // 1.0 = default
  floorY: number;         // y position of floor line (200)
}

export type FurnitureRenderer = (ctx: FurnitureContext) => string;
// Returns SVG group inner HTML including drop shadow
