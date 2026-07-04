import type { FurnitureRenderer } from './types';

export const renderBall: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const r = 10 * s;
  return `
    <ellipse cx="${x}" cy="${y + r * 0.8}" rx="${r * 0.7}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="#ef4444"/>
    <path d="M${x - r},${y} Q${x},${y - r} ${x + r},${y}" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
    <path d="M${x - r * 0.7},${y + r * 0.7} Q${x},${y} ${x + r * 0.7},${y - r * 0.7}" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
  `;
};
