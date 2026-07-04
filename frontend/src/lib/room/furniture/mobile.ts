import type { FurnitureRenderer } from './types';

export const renderMobile: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <line x1="${x}" y1="${y - 22 * s}" x2="${x}" y2="${y + 5 * s}" stroke="#9ca3af" stroke-width="0.8"/>
    <line x1="${x}" y1="${y - 2 * s}" x2="${x - 12 * s}" y2="${y + 10 * s}" stroke="#9ca3af" stroke-width="0.5"/>
    <line x1="${x}" y1="${y - 2 * s}" x2="${x + 12 * s}" y2="${y + 10 * s}" stroke="#9ca3af" stroke-width="0.5"/>
    <polygon points="${x},${y + 5 * s} ${x + 4},${y + 11 * s} ${x + 8},${y + 11 * s} ${x + 5},${y + 14 * s} ${x + 6},${y + 19 * s} ${x},${y + 16 * s} ${x - 6},${y + 19 * s} ${x - 5},${y + 14 * s} ${x - 8},${y + 11 * s} ${x - 4},${y + 11 * s}"
      fill="#fbbf24" opacity="0.8">
      <animateTransform attributeName="transform" type="rotate" values="-5,${x},${y - 22 * s};5,${x},${y - 22 * s};-5,${x},${y - 22 * s}" dur="4s" repeatCount="indefinite"/>
    </polygon>
  `;
};
