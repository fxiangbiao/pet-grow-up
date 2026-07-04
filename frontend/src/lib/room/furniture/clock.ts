import type { FurnitureRenderer } from './types';

export const renderClock: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const r = 10 * s;
  return `
    <circle cx="${x}" cy="${y}" r="${r}" fill="#fff" stroke="#8B7355" stroke-width="1.5"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.85}" fill="none" stroke="#d4a574" stroke-width="0.5"/>
    <line x1="${x}" y1="${y}" x2="${x - r * 0.35}" y2="${y - r * 0.45}" stroke="#374151" stroke-width="1.5" stroke-linecap="round"/>
    <line x1="${x}" y1="${y}" x2="${x + r * 0.4}" y2="${y - r * 0.3}" stroke="#374151" stroke-width="1" stroke-linecap="round"/>
    <circle cx="${x}" cy="${y}" r="1.5" fill="#ef4444"/>
  `;
};
