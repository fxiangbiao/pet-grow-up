import type { FurnitureRenderer } from './types';

export const renderRug: FurnitureRenderer = (ctx) => {
  const { x, y, scale } = ctx;
  const s = scale;
  const rx = 35 * s, ry = 10 * s;
  return `
    <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#f472b6" opacity="0.3"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.85}" ry="${ry * 0.75}" fill="none" stroke="#ec4899" stroke-width="0.8" opacity="0.4"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.6}" ry="${ry * 0.45}" fill="none" stroke="#ec4899" stroke-width="0.5" opacity="0.3" stroke-dasharray="3,3"/>
  `;
};
