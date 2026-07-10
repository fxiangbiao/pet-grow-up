// frontend/src/lib/accessories/renderers/effects.ts
import type { AccessoryRenderer } from '../types';

function renderGoldSparkle(ctx: { cx: number; cy: number; half: number }): string {
  const r = ctx.half * 0.8;
  const cx = ctx.cx;
  const cy = ctx.cy;
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
    return `<ellipse cx="${cx}" cy="${cy}" rx="${r + i * 3}" ry="${r * 0.6 + i * 2}"
      fill="none" stroke="${c}" stroke-width="1.5" opacity="0.4">
      <animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" begin="${offset}s" repeatCount="indefinite"/>
    </ellipse>`;
  }).join('');
}

export const effectsRenderers: Record<string, AccessoryRenderer> = {
  acc_effect_gold:    (ctx) => ({ svg: renderGoldSparkle(ctx) }),
  acc_effect_rainbow: (ctx) => ({ svg: renderRainbowAura(ctx) }),
};
