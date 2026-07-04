// frontend/src/lib/accessories/renderers/eyes.ts
import type { AccessoryRenderer } from '../types';

function eyeCenter(ctx: { cy: number; half: number }): number {
  return ctx.cy - ctx.half * 0.08; // matches SpiritAvatar eye Y
}

function renderRoundGlasses(ctx: { cx: number; cy: number; half: number; eyeOffsetX: number; eyeOffsetY: number }): string {
  const ey = eyeCenter(ctx);
  const es = ctx.half * 0.3;
  const er = ctx.half * 0.11;
  const cx = ctx.cx;
  const ox = ctx.eyeOffsetX;
  const oy = ctx.eyeOffsetY;
  return `
    <circle cx="${cx - es + ox}" cy="${ey + oy}" r="${er}" fill="none" stroke="#374151" stroke-width="1.5" opacity="0.7"/>
    <circle cx="${cx + es + ox}" cy="${ey + oy}" r="${er}" fill="none" stroke="#374151" stroke-width="1.5" opacity="0.7"/>
    <line x1="${cx - es + er + ox}" y1="${ey + oy}" x2="${cx + es - er + ox}" y2="${ey + oy}"
      stroke="#374151" stroke-width="1" opacity="0.5"/>
  `;
}

function renderStarShades(ctx: { cx: number; cy: number; half: number; eyeOffsetX: number; eyeOffsetY: number }): string {
  const ey = eyeCenter(ctx);
  const es = ctx.half * 0.3;
  const rs = ctx.half * 0.13;
  const cx = ctx.cx;
  const ox = ctx.eyeOffsetX;
  const oy = ctx.eyeOffsetY;

  function starPath(sx: number, sy: number): string {
    const pts: string[] = [];
    for (let i = 0; i < 5; i++) {
      const a = (Math.PI / 2.5) * i - Math.PI / 2;
      pts.push(`${sx + rs * Math.cos(a)},${sy + rs * Math.sin(a)}`);
    }
    return pts.join(' ');
  }

  return `
    <polygon points="${starPath(cx - es + ox, ey + oy)}" fill="#1e1b4b" stroke="#fbbf24" stroke-width="1" opacity="0.8"/>
    <polygon points="${starPath(cx + es + ox, ey + oy)}" fill="#1e1b4b" stroke="#fbbf24" stroke-width="1" opacity="0.8"/>
    <line x1="${cx - es + rs + ox}" y1="${ey + oy}" x2="${cx + es - rs + ox}" y2="${ey + oy}"
      stroke="#fbbf24" stroke-width="0.8" opacity="0.5"/>
  `;
}

export const eyesRenderers: Record<string, AccessoryRenderer> = {
  acc_round_glasses: (ctx) => ({ svg: renderRoundGlasses(ctx) }),
  acc_star_shades:   (ctx) => ({ svg: renderStarShades(ctx) }),
};
