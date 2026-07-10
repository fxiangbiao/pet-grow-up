// frontend/src/lib/accessories/types.ts

export interface RenderContext {
  cx: number;
  cy: number;
  half: number;           // icon half-size, varies by sm/md/lg
  primaryColor: string;
  secondaryColor: string;
  accentColor: string;
  stage: number;          // evolution stage 1-3
  subject: 'chinese' | 'math' | 'english';
  eyeOffsetX: number;     // eye tracking offset for glasses sync
  eyeOffsetY: number;
}

export interface SvgFragment {
  svg: string;            // SVG inner HTML (no <svg> wrapper)
  offsetY?: number;       // optional vertical adjustment
}

export type AccessoryRenderer = (ctx: RenderContext) => SvgFragment;
