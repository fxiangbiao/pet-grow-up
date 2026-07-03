// ── Adventure Map Type System ──

export type StationType = 'study' | 'treasure' | 'rest' | 'guardian';

export interface Point {
  x: number;
  y: number;
}

export interface StationTheme {
  emoji: string;
  name: string;
  color: string;    // Tailwind bg class for the station circle
  border: string;   // Tailwind border class
  glow: string;     // CSS drop-shadow color
}

export interface SubjectLandscape {
  skyGradient: { from: string; to: string };  // Tailwind gradient stops
  groundColor: string;
  decorations: 'mountains' | 'crystals' | 'forest';
  accentColor: string;   // hex color for path and highlights
  pathGlow: string;      // hex color for path glow
}

// ── Station count to type assignment ──

/**
 * Assigns station types for a given total count.
 * Last station is always 'guardian'.
 * Rest stations appear ~1/3 through. Treasure ~2/3 through.
 * All others are 'study'.
 */
export function assignStationTypes(count: number): StationType[] {
  const types: StationType[] = [];
  for (let i = 0; i < count; i++) {
    if (i === count - 1) {
      types.push('guardian');
    } else if (count >= 5 && i === Math.floor(count / 3) && i > 0) {
      types.push('rest');
    } else if (count >= 5 && i === Math.floor((count * 2) / 3) && i < count - 1) {
      types.push('treasure');
    } else {
      types.push('study');
    }
  }
  return types;
}

// ── Station theme by type ──

export function getStationTheme(type: StationType): StationTheme {
  switch (type) {
    case 'study':
      return { emoji: '📖', name: '学习站', color: 'bg-sky-100', border: 'border-sky-400', glow: '#38bdf8' };
    case 'treasure':
      return { emoji: '💎', name: '宝箱站', color: 'bg-amber-100', border: 'border-amber-400', glow: '#fbbf24' };
    case 'rest':
      return { emoji: '🏕️', name: '休息站', color: 'bg-emerald-100', border: 'border-emerald-400', glow: '#34d399' };
    case 'guardian':
      return { emoji: '🛡️', name: '守护者', color: 'bg-violet-100', border: 'border-violet-500', glow: '#a78bfa' };
    default:
      return { emoji: '📖', name: '学习站', color: 'bg-sky-100', border: 'border-sky-400', glow: '#38bdf8' };
  }
}

// ── Subject landscape theming ──

export function getSubjectLandscape(subject: string): SubjectLandscape {
  switch (subject) {
    case 'chinese':
      return {
        skyGradient: { from: 'from-amber-50', to: 'to-orange-100' },
        groundColor: 'bg-stone-200',
        decorations: 'mountains',
        accentColor: '#d97706',   // amber-600
        pathGlow: '#fbbf24',      // amber-400
      };
    case 'math':
      return {
        skyGradient: { from: 'from-blue-50', to: 'to-indigo-100' },
        groundColor: 'bg-slate-200',
        decorations: 'crystals',
        accentColor: '#4f46e5',   // indigo-600
        pathGlow: '#818cf8',      // indigo-400
      };
    case 'english':
      return {
        skyGradient: { from: 'from-purple-50', to: 'to-pink-100' },
        groundColor: 'bg-emerald-100',
        decorations: 'forest',
        accentColor: '#7c3aed',   // violet-600
        pathGlow: '#a78bfa',      // violet-400
      };
    default:
      return {
        skyGradient: { from: 'from-sky-50', to: 'to-indigo-100' },
        groundColor: 'bg-slate-200',
        decorations: 'crystals',
        accentColor: '#4f46e5',
        pathGlow: '#818cf8',
      };
  }
}

// ── Guardian data per subject ──

export interface GuardianData {
  name: string;
  emoji: string;
  title: string;
  greeting: string;
  purified: string;
  encouragement: string;
}

export function getGuardianData(subject: string): GuardianData {
  switch (subject) {
    case 'chinese':
      return {
        name: '文曲星君',
        emoji: '🐲',
        title: '诗词大陆的守护仙灵',
        greeting: '远道而来的学习者啊，让我看看你在此地学到了什么！',
        purified: '你的学识之光驱散了黑暗！诗韵之力因你而重燃！',
        encouragement: '不必灰心，学习之路漫长。下次你定能绽放更耀眼的光芒！',
      };
    case 'math':
      return {
        name: '几何贤者',
        emoji: '🦉',
        title: '智慧王国的远古智者',
        greeting: '年轻的探索者，逻辑之光在你身上闪耀。接受我的考验吧！',
        purified: '万物皆数！你已经掌握了智慧的真谛！',
        encouragement: '逻辑之塔需要耐心攀登。继续学习，下次再来挑战！',
      };
    case 'english':
      return {
        name: '字母精灵王',
        emoji: '🦄',
        title: '魔法学院的守护精灵',
        greeting: 'Welcome, young wizard! Show me the magic of your words!',
        purified: 'Excellent! Your English magic has restored the academy!',
        encouragement: 'Don\'t worry! Every spell needs practice. Keep studying!',
      };
    default:
      return {
        name: '守护者',
        emoji: '🛡️',
        title: '冒险的守护者',
        greeting: '来吧，展示你的学习成果！',
        purified: '你做到了！守护者被你用知识的力量净化了！',
        encouragement: '继续加油！学习让一切成为可能！',
      };
  }
}

// ── SVG Path Generation ──

/**
 * Generates a winding SVG path from bottom-left to top-right
 * with sine-wave superimposed on the diagonal.
 *
 * @param count    Number of stations
 * @param viewW    SVG viewBox width (default 600)
 * @param viewH    SVG viewBox height (default 400)
 * @returns        SVG path `d` string and station point array
 */
export function generateWindingPath(
  count: number,
  viewW: number = 600,
  viewH: number = 400
): { pathD: string; points: Point[] } {
  const padX = 70;
  const padY = 60;

  const startX = padX;
  const startY = viewH - padY;
  const endX = viewW - padX;
  const endY = padY;

  // First pass: compute station positions along sine-superimposed diagonal
  const points: Point[] = [];
  for (let i = 0; i < count; i++) {
    const t = count > 1 ? i / (count - 1) : 0.5;
    const baseX = startX + t * (endX - startX);
    const baseY = startY + t * (endY - startY);

    // Sine wave offset — amplitude peaks in middle, tapers at ends
    const waveAmplitude = viewH * 0.22;
    const wave = Math.sin(t * Math.PI * 2.2) * waveAmplitude * (1 - Math.abs(t - 0.5) * 0.7);

    points.push({
      x: baseX + wave * 0.3,
      y: baseY - wave,
    });
  }

  // Second pass: build cubic bezier chain
  let d = `M ${points[0].x.toFixed(1)} ${points[0].y.toFixed(1)}`;
  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1];
    const curr = points[i];
    const segLen = Math.sqrt((curr.x - prev.x) ** 2 + (curr.y - prev.y) ** 2);
    const cpLen = segLen * 0.35;

    let angle = Math.atan2(curr.y - prev.y, curr.x - prev.x);
    // Alternate bend direction for winding feel
    const bend = (i % 2 === 0 ? 0.5 : -0.5);
    angle += bend;

    const cp1x = prev.x + cpLen * Math.cos(angle);
    const cp1y = prev.y + cpLen * Math.sin(angle);
    const cp2x = curr.x - cpLen * Math.cos(angle);
    const cp2y = curr.y - cpLen * Math.sin(angle);

    d += ` C ${cp1x.toFixed(1)} ${cp1y.toFixed(1)}, ${cp2x.toFixed(1)} ${cp2y.toFixed(1)}, ${curr.x.toFixed(1)} ${curr.y.toFixed(1)}`;
  }

  return { pathD: d, points };
}

// ── Path segment builder (for per-segment glow animation) ──

export function getPathSegments(points: Point[]): { x1: number; y1: number; x2: number; y2: number }[] {
  const segments: { x1: number; y1: number; x2: number; y2: number }[] = [];
  for (let i = 1; i < points.length; i++) {
    segments.push({
      x1: points[i - 1].x,
      y1: points[i - 1].y,
      x2: points[i].x,
      y2: points[i].y,
    });
  }
  return segments;
}
