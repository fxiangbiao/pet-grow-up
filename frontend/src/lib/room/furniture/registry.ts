// frontend/src/lib/room/furniture/registry.ts
import type { FurnitureRenderer } from './types';
import { renderBed } from './bed';
import { renderSofa } from './sofa';
import { renderBookshelf } from './bookshelf';
import { renderLamp } from './lamp';
import { renderRug } from './rug';
import { renderPlant } from './plant';
import { renderWindowDeco } from './window';
import { renderPoster } from './poster';
import { renderBall } from './ball';
import { renderMobile } from './mobile';
import { renderTable } from './table';
import { renderClock } from './clock';

export const furnitureRegistry: Map<string, FurnitureRenderer> = new Map([
  ['deco_bed_small',    renderBed],
  ['deco_sofa',         renderSofa],
  ['deco_bookshelf',    renderBookshelf],
  ['deco_lamp',         renderLamp],
  ['deco_rug_round',    renderRug],
  ['deco_plant',        renderPlant],
  ['deco_window',       renderWindowDeco],
  ['deco_poster',       renderPoster],
  ['deco_toy_ball',     renderBall],
  ['deco_star_mobile',  renderMobile],
  ['deco_table',        renderTable],
  ['deco_clock',        renderClock],
]);

export function getFurnitureRenderer(itemKey: string): FurnitureRenderer | undefined {
  return furnitureRegistry.get(itemKey);
}
