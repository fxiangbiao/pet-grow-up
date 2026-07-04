// frontend/src/lib/accessories/renderers/neck.ts
import type { AccessoryRenderer } from '../types';

function neckY(ctx: { cy: number; half: number; subject: string }): number {
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
    <rect x="${cx + w * 0.3}" y="${y + ctx.half * 0.05}" width="${w * 0.25}" height="${ctx.half * 0.35}"
      fill="#3b82f6" rx="2" transform="rotate(10,${cx + w * 0.3},${y + ctx.half * 0.05})"/>
    <line x1="${cx - w * 0.9}" y1="${y}" x2="${cx - w * 0.7}" y2="${y + ctx.half * 0.08}"
      stroke="#93c5fd" stroke-width="1.5" stroke-linecap="round"/>
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
  return `
    <path d="M${cx - r},${y - ctx.half * 0.1} Q${cx - r * 0.7},${y + ctx.half * 0.2} ${cx},${y + ctx.half * 0.08}
      Q${cx + r * 0.7},${y + ctx.half * 0.2} ${cx + r},${y - ctx.half * 0.1}"
      fill="none" stroke="#fbbf24" stroke-width="1.2" stroke-dasharray="2,1"/>
    <polygon points="${cx},${y + ctx.half * 0.02} ${cx + 3},${y + ctx.half * 0.1} ${cx + 8},${y + ctx.half * 0.1}
      ${cx + 4},${y + ctx.half * 0.15} ${cx + 5},${y + ctx.half * 0.22} ${cx},${y + ctx.half * 0.18}
      ${cx - 5},${y + ctx.half * 0.22} ${cx - 4},${y + ctx.half * 0.15} ${cx - 8},${y + ctx.half * 0.1}
      ${cx - 3},${y + ctx.half * 0.1}"
      fill="#fbbf24" stroke="#f59e0b" stroke-width="0.5"/>
  `;
}

function renderPerseveranceScarf(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = neckY(ctx);
  const w = ctx.half * 0.42;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx}" cy="${y}" rx="${w}" ry="${ctx.half * 0.13}" fill="#fbbf24" stroke="#f59e0b" stroke-width="1.2"/>
    <rect x="${cx + w * 0.25}" y="${y + ctx.half * 0.04}" width="${w * 0.22}" height="${ctx.half * 0.38}"
      fill="#f59e0b" rx="2" transform="rotate(8,${cx + w * 0.25},${y + ctx.half * 0.04})"/>
    <text x="${cx}" y="${y + 3}" text-anchor="middle" font-size="${ctx.half * 0.15}" fill="#d97706">★</text>
  `;
}

export const neckRenderers: Record<string, AccessoryRenderer> = {
  acc_scarf_blue:          (ctx) => ({ svg: renderBlueScarf(ctx) }),
  acc_bowtie:              (ctx) => ({ svg: renderBowtie(ctx) }),
  acc_star_necklace:       (ctx) => ({ svg: renderStarNecklace(ctx) }),
  acc_perseverance_scarf:  (ctx) => ({ svg: renderPerseveranceScarf(ctx) }),
};
