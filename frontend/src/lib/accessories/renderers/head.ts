// frontend/src/lib/accessories/renderers/head.ts
import type { AccessoryRenderer } from '../types';

/** Adjust hat Y anchor based on spirit subject */
function hatAnchorY(ctx: { subject: string; cy: number; half: number }): number {
  switch (ctx.subject) {
    case 'chinese': return ctx.cy - ctx.half * 0.52;  // above flat scholar hat
    case 'math':    return ctx.cy - ctx.half * 0.55;  // between cat ears
    case 'english': return ctx.cy - ctx.half * 0.68;  // on wizard hat cone
    default:        return ctx.cy - ctx.half * 0.50;
  }
}

function renderRedHat(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx);
  const w = ctx.half * 0.5;
  const h = ctx.half * 0.22;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx}" cy="${y}" rx="${w}" ry="${h}" fill="#ef4444" stroke="#b91c1c" stroke-width="1"/>
    <rect x="${cx - w * 1.05}" y="${y}" width="${w * 2.1}" height="${h * 0.35}" rx="2" fill="#dc2626"/>
    <circle cx="${cx}" cy="${y - h * 0.4}" r="${h * 0.25}" fill="#fbbf24"/>
  `;
}

function renderBow(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx) + ctx.half * 0.05;
  const s = ctx.half * 0.22;
  const cx = ctx.cx;
  return `
    <ellipse cx="${cx - s}" cy="${y - s * 0.5}" rx="${s}" ry="${s * 0.7}" fill="#f472b6"
      transform="rotate(-20,${cx - s},${y - s * 0.5})"/>
    <ellipse cx="${cx + s}" cy="${y - s * 0.5}" rx="${s}" ry="${s * 0.7}" fill="#f472b6"
      transform="rotate(20,${cx + s},${y - s * 0.5})"/>
    <circle cx="${cx}" cy="${y}" r="${s * 0.3}" fill="#ec4899"/>
  `;
}

function renderFlowerCrown(ctx: { cx: number; cy: number; half: number; subject: string }): string {
  const y = hatAnchorY(ctx) + ctx.half * 0.08;
  const r = ctx.half * 0.55;
  const cx = ctx.cx;
  const colors = ['#fbbf24', '#f472b6', '#a78bfa', '#fb923c', '#f87171', '#fbbf24'];
  return [0, 60, 120, 180, 240, 300].map((angle, i) => {
    const fx = cx + r * Math.cos((angle * Math.PI) / 180);
    const fy = y + r * Math.sin((angle * Math.PI) / 180) * 0.4;
    return `<circle cx="${fx}" cy="${fy}" r="${ctx.half * 0.1}" fill="${colors[i]}" opacity="0.9"/>`;
  }).join('');
}

function renderGraduationCap(ctx: { cx: number; cy: number; half: number; subject: string }): string {
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
