<script lang="ts">
  import type { Point, SubjectLandscape } from '$lib/types/adventure-map';

  let {
    pathD,
    stationPoints = [],
    reachedCount = 0,
    landscape,
  }: {
    pathD: string;
    stationPoints: Point[];
    reachedCount: number;
    landscape: SubjectLandscape;
  } = $props();

  // ── Landscape decorations by type ──
  const showMountains = $derived(landscape.decorations === 'mountains');
  const showCrystals = $derived(landscape.decorations === 'crystals');
  const showForest = $derived(landscape.decorations === 'forest');

  // ── Build reached path D string ──
  const reachedPathD = $derived.by(() => {
    const endIdx = Math.min(reachedCount, stationPoints.length - 1);
    if (endIdx < 1) return '';
    const pts = stationPoints.slice(0, endIdx + 1);
    const parts: string[] = [];
    for (let i = 0; i < pts.length; i++) {
      if (i === 0) {
        parts.push(`M ${pts[i].x.toFixed(1)} ${pts[i].y.toFixed(1)}`);
      } else {
        parts.push(`L ${pts[i].x.toFixed(1)} ${pts[i].y.toFixed(1)}`);
      }
    }
    return parts.join(' ');
  });
</script>

<svg width="600" height="400" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg" class="w-full h-full">
  <!-- ── Background ── -->
  <defs>
    <filter id="path-glow">
      <feGaussianBlur stdDeviation="3" result="blur" />
      <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>
    <filter id="station-glow">
      <feGaussianBlur stdDeviation="2" result="blur" />
      <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>
    <linearGradient id="pathGrad" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0%" stop-color={landscape.accentColor} stop-opacity="0.3" />
      <stop offset="100%" stop-color={landscape.accentColor} stop-opacity="0.8" />
    </linearGradient>
  </defs>

  <!-- ── Sky gradient rect ── -->
  <rect x="0" y="0" width="600" height="400" fill="#f8fafc" rx="16" />

  {#if showMountains}
    <!-- Ink-wash mountains -->
    <path d="M 0,350 Q 60,280 120,320 Q 180,260 240,300 Q 320,230 400,290 Q 480,250 600,310 L 600,400 L 0,400 Z"
          fill="#d6d3d1" opacity="0.6" />
    <path d="M 0,370 Q 100,320 200,350 Q 300,300 400,340 Q 500,290 600,350 L 600,400 L 0,400 Z"
          fill="#a8a29e" opacity="0.4" />
    <!-- Cloud wisps -->
    <ellipse cx="150" cy="100" rx="60" ry="15" fill="white" opacity="0.5" />
    <ellipse cx="170" cy="95" rx="40" ry="12" fill="white" opacity="0.4" />
    <ellipse cx="420" cy="140" rx="50" ry="12" fill="white" opacity="0.4" />
    <!-- Plum blossom dots -->
    <circle cx="80" cy="200" r="4" fill="#f43f5e" opacity="0.3" />
    <circle cx="500" cy="180" r="3" fill="#f43f5e" opacity="0.25" />
    <circle cx="520" cy="170" r="5" fill="#f43f5e" opacity="0.2" />
  {:else if showCrystals}
    <!-- Geometric crystal formations -->
    <polygon points="120,380 140,310 160,380" fill="#818cf8" opacity="0.15" />
    <polygon points="145,380 165,280 185,380" fill="#6366f1" opacity="0.12" />
    <polygon points="400,380 425,290 450,380" fill="#818cf8" opacity="0.15" />
    <polygon points="430,380 450,320 470,380" fill="#6366f1" opacity="0.1" />
    <!-- Rainbow arc -->
    <path d="M 200,380 Q 300,200 400,380" fill="none" stroke="#fbbf24" stroke-width="3" opacity="0.2" />
    <path d="M 220,380 Q 300,220 380,380" fill="none" stroke="#f472b6" stroke-width="2" opacity="0.15" />
    <!-- Grid lines (isometric feel) -->
    <line x1="50" y1="380" x2="550" y2="380" stroke="#94a3b8" stroke-width="1" opacity="0.15" />
    <line x1="0" y1="350" x2="600" y2="350" stroke="#94a3b8" stroke-width="1" opacity="0.1" stroke-dasharray="4,8" />
  {:else if showForest}
    <!-- Rolling hills -->
    <path d="M 0,340 Q 80,300 160,330 Q 250,290 340,320 Q 440,280 600,310 L 600,400 L 0,400 Z"
          fill="#86efac" opacity="0.3" />
    <path d="M 0,370 Q 120,340 240,360 Q 360,320 480,350 Q 540,330 600,350 L 600,400 L 0,400 Z"
          fill="#4ade80" opacity="0.2" />
    <!-- Sparkle stars -->
    <circle cx="100" cy="80" r="2" fill="#fbbf24" opacity="0.6" />
    <circle cx="250" cy="60" r="2.5" fill="#fbbf24" opacity="0.5" />
    <circle cx="450" cy="100" r="2" fill="#fbbf24" opacity="0.5" />
    <circle cx="350" cy="130" r="1.5" fill="#fbbf24" opacity="0.4" />
    <circle cx="520" cy="70" r="2" fill="#fbbf24" opacity="0.5" />
    <!-- Distant castle silhouette -->
    <rect x="490" y="100" width="40" height="30" fill="#a78bfa" opacity="0.2" rx="2" />
    <rect x="495" y="90" width="10" height="15" fill="#a78bfa" opacity="0.15" rx="1" />
    <rect x="515" y="90" width="10" height="15" fill="#a78bfa" opacity="0.15" rx="1" />
  {/if}

  <!-- ── Winding path: background thick stroke ── -->
  <path d={pathD}
        fill="none"
        stroke="url(#pathGrad)"
        stroke-width="18"
        stroke-linecap="round"
        stroke-linejoin="round"
        opacity="0.25" />

  <!-- ── Winding path: main thin stroke ── -->
  <path d={pathD}
        fill="none"
        stroke={landscape.accentColor}
        stroke-width="4"
        stroke-linecap="round"
        stroke-linejoin="round"
        opacity="0.5"
        filter="url(#path-glow)" />

  <!-- ── Winding path: inner dash for "road" feel ── -->
  <path d={pathD}
        fill="none"
        stroke="white"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-dasharray="8,12"
        opacity="0.6" />

  <!-- ── Reached path segments (lit up) ── -->
  {#if reachedCount > 0 && stationPoints.length > 1}
    {@const endIdx = Math.min(reachedCount, stationPoints.length - 1)}
    <path d={reachedPathD}
          fill="none"
          stroke={landscape.accentColor}
          stroke-width="5"
          stroke-linecap="round"
          stroke-linejoin="round"
          opacity="0.9"
          filter="url(#path-glow)" />
  {/if}

  <!-- ── Station position indicators (subtle dots on path) ── -->
  {#each stationPoints as pt, i}
    <circle cx={pt.x} cy={pt.y} r="4"
            fill={i < reachedCount ? landscape.accentColor : '#cbd5e1'}
            opacity={i < reachedCount ? 0.8 : 0.4} />
  {/each}
</svg>
