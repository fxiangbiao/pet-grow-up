import type { FurnitureRenderer } from './types';

export const renderLamp: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <ellipse cx="${x}" cy="${y + 10}" rx="${8 * s}" ry="3" fill="rgba(0,0,0,0.1)"/>
    <line x1="${x}" y1="${y - 20 * s}" x2="${x}" y2="${y + 8 * s}" stroke="#6b7280" stroke-width="2"/>
    <ellipse cx="${x}" cy="${y + 8 * s}" rx="${6 * s}" ry="${2 * s}" fill="#4b5563"/>
    <polygon points="${x - 8 * s},${y - 15 * s} ${x + 8 * s},${y - 15 * s} ${x + 5 * s},${y - 22 * s} ${x - 5 * s},${y - 22 * s}"
      fill="#fef3c7" stroke="#f59e0b" stroke-width="0.8"/>
    <circle cx="${x}" cy="${y - 15 * s}" r="${10 * s}" fill="url(#lampGlow)" opacity="0.4">
      <animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" repeatCount="indefinite"/>
    </circle>
  `;
};
