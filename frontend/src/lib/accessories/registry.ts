// frontend/src/lib/accessories/registry.ts
import type { AccessoryRenderer } from './types';
import { headRenderers } from './renderers/head';
import { neckRenderers } from './renderers/neck';
import { eyesRenderers } from './renderers/eyes';
import { effectsRenderers } from './renderers/effects';

export const accessoryRegistry: Map<string, AccessoryRenderer> = new Map([
  ...Object.entries(headRenderers),
  ...Object.entries(neckRenderers),
  ...Object.entries(eyesRenderers),
  ...Object.entries(effectsRenderers),
]);

export function getAccessoryRenderer(itemKey: string): AccessoryRenderer | undefined {
  return accessoryRegistry.get(itemKey);
}
