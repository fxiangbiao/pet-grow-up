import type { FurnitureRenderer } from './types';

export const renderPlant: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  return `
    <ellipse cx="${x}" cy="${y + 4}" rx="${7 * s}" ry="2" fill="rgba(0,0,0,0.1)"/>
    <polygon points="${x - 5 * s},${y - 6 * s} ${x + 5 * s},${y - 6 * s} ${x + 4 * s},${y + 3 * s} ${x - 4 * s},${y + 3 * s}"
      fill="#d97706" stroke="#b45309" stroke-width="0.8"/>
    <rect x="${x - 5.5 * s}" y="${y - 7 * s}" width="${11 * s}" height="${1.5 * s}" rx="1" fill="#b45309"/>
    <line x1="${x}" y1="${y - 7 * s}" x2="${x}" y2="${y - 18 * s}" stroke="#22c55e" stroke-width="1.5"/>
    <ellipse cx="${x - 4 * s}" cy="${y - 13 * s}" rx="${5 * s}" ry="${3 * s}" fill="#22c55e" transform="rotate(-30,${x - 4 * s},${y - 13 * s})"/>
    <ellipse cx="${x + 4 * s}" cy="${y - 15 * s}" rx="${5 * s}" ry="${3 * s}" fill="#16a34a" transform="rotate(25,${x + 4 * s},${y - 15 * s})"/>
    <ellipse cx="${x - 1 * s}" cy="${y - 18 * s}" rx="${4 * s}" ry="${2.5 * s}" fill="#4ade80" transform="rotate(-10,${x - 1 * s},${y - 18 * s})"/>
  `;
};
