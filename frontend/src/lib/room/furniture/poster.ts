import type { FurnitureRenderer } from './types';

export const renderPoster: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const w = 14 * s, h = 20 * s;
  return `
    <rect x="${x - w}" y="${y - h}" width="${w * 2}" height="${h * 2}" rx="1" fill="#fef3c7" stroke="#d4a574" stroke-width="1"/>
    <rect x="${x - w + 3}" y="${y - h + 3}" width="${w * 2 - 6}" height="${h * 2 - 6}" fill="none" stroke="#f59e0b" stroke-width="0.5" rx="1"/>
    ${[0.3, 0.45, 0.6, 0.75].map(py => `<line x1="${x - w + 5}" y1="${y - h + py * h * 2}" x2="${x + w - 5}" y2="${y - h + py * h * 2}" stroke="#d4a574" stroke-width="0.8" opacity="0.5"/>`).join('')}
    <text x="${x}" y="${y - h * 0.2}" text-anchor="middle" font-size="${6 * s}" fill="#f59e0b">★</text>
  `;
};
