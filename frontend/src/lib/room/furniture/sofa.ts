// frontend/src/lib/room/furniture/sofa.ts
import type { FurnitureRenderer } from './types';

export const renderSofa: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 25 * s, h = 14 * s;
  return `
    <ellipse cx="${x}" cy="${y + h * 0.5 + 2}" rx="${w * 0.8}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <rect x="${x - w}" y="${y - h * 0.3}" width="${w * 2}" height="${h}" rx="4" fill="#fbbf24" stroke="#f59e0b" stroke-width="1"/>
    <rect x="${x - w}" y="${y - h * 0.5}" width="${w * 0.3}" height="${h * 0.7}" rx="3" fill="#f59e0b"/>
    <rect x="${x + w - w * 0.3}" y="${y - h * 0.5}" width="${w * 0.3}" height="${h * 0.7}" rx="3" fill="#f59e0b"/>
    <rect x="${x - w * 0.6}" y="${y - h * 0.3}" width="${w * 0.7}" height="${h * 0.4}" rx="2" fill="#fef3c7"/>
    <rect x="${x + w * 0.05}" y="${y - h * 0.3}" width="${w * 0.7}" height="${h * 0.4}" rx="2" fill="#fef3c7"/>
  `;
};
