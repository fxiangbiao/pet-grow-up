// frontend/src/lib/room/furniture/bed.ts
import type { FurnitureRenderer } from './types';

export const renderBed: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 30 * s, h = 18 * s;
  return `
    <ellipse cx="${x}" cy="${y + h * 0.5 + 2}" rx="${w * 0.9}" ry="4" fill="rgba(0,0,0,0.12)"/>
    <rect x="${x - w}" y="${y - h * 0.4}" width="${w * 2}" height="${h}" rx="3" fill="#d4a574" stroke="#b8875a" stroke-width="1"/>
    <rect x="${x - w}" y="${y - h * 0.7}" width="${w * 2}" height="${h * 0.4}" rx="2" fill="#c49564" stroke="#a0704a" stroke-width="0.8"/>
    <ellipse cx="${x - w * 0.5}" cy="${y - h * 0.25}" rx="${w * 0.6}" ry="${h * 0.25}" fill="#fff" opacity="0.9"/>
    <rect x="${x - w * 0.3}" y="${y - h * 0.2}" width="${w * 1.3}" height="${h * 0.7}" rx="2" fill="#93c5fd" opacity="0.8"/>
    <line x1="${x - w * 0.2}" y1="${y - h * 0.2}" x2="${x - w * 0.2}" y2="${y + h * 0.5}" stroke="#60a5fa" stroke-width="0.5" opacity="0.5"/>
    <line x1="${x + w * 0.3}" y1="${y - h * 0.2}" x2="${x + w * 0.3}" y2="${y + h * 0.5}" stroke="#60a5fa" stroke-width="0.5" opacity="0.5"/>
  `;
};
