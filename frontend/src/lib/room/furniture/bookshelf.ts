import type { FurnitureRenderer } from './types';

export const renderBookshelf: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 15 * s, h = 27 * s;
  const colors = ['#ef4444','#3b82f6','#22c55e','#fbbf24','#a855f7','#ec4899','#f97316','#06b6d4'];
  return `
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 2}" rx="1" fill="#8B5E3C" stroke="#6B3F2C" stroke-width="1"/>
    <line x1="${x - w + 2}" y1="${y - h + h * 0.5}" x2="${x + w - 2}" y2="${y - h + h * 0.5}" stroke="#6B3F2C" stroke-width="1"/>
    <line x1="${x - w + 2}" y1="${y - h + h * 1.0}" x2="${x + w - 2}" y2="${y - h + h * 1.0}" stroke="#6B3F2C" stroke-width="1"/>
    <line x1="${x - w + 2}" y1="${y - h + h * 1.5}" x2="${x + w - 2}" y2="${y - h + h * 1.5}" stroke="#6B3F2C" stroke-width="1"/>
    ${[0,1,2,3].map(i => `<rect x="${x - w + 3 + i * 7}" y="${y - h + h * 0.1}" width="5" height="${h * 0.35}" fill="${colors[i]}" rx="0.5" opacity="0.8"/>`).join('')}
    ${[0,1,2].map(i => `<rect x="${x - w + 4 + i * 8}" y="${y - h + h * 0.6}" width="5" height="${h * 0.35}" fill="${colors[i + 4]}" rx="0.5" opacity="0.8"/>`).join('')}
    <rect x="${x - w + 5}" y="${y - h + h * 1.4}" width="14" height="3" fill="#ef4444" rx="0.5" opacity="0.7"/>
    <rect x="${x - w + 6}" y="${y - h + h * 1.35}" width="13" height="3" fill="#3b82f6" rx="0.5" opacity="0.7"/>
  `;
};
