import type { FurnitureRenderer } from './types';

export const renderTable: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 18 * s, h = 5 * s;
  return `
    <ellipse cx="${x}" cy="${y + h + 2}" rx="${w * 0.8}" ry="2" fill="rgba(0,0,0,0.1)"/>
    <line x1="${x - w * 0.6}" y1="${y}" x2="${x - w * 0.5}" y2="${y + h + 3}" stroke="#8B7355" stroke-width="2"/>
    <line x1="${x + w * 0.6}" y1="${y}" x2="${x + w * 0.5}" y2="${y + h + 3}" stroke="#8B7355" stroke-width="2"/>
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 1.5}" rx="2" fill="#d4a574" stroke="#b8875a" stroke-width="1"/>
  `;
};
