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
    <rect x="${x - w - 1}" y="${y - h - 1}" width="6" height="${h * 2 + 2}" fill="#ffb3ba" rx="2" opacity="0.7"/>
    <rect x="${x + w - 5}" y="${y - h - 1}" width="6" height="${h * 2 + 2}" fill="#ffb3ba" rx="2" opacity="0.7"/>
  `;
};
