<script lang="ts">
  import EnemySprite from './EnemySprite.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    subject = 'math',
    nodeCount = 5,
    currentNodeIndex = 0,
    nodeResults = [] as Array<boolean | null>,
    nodeHps = [] as number[],
    nodeMaxHps = [] as number[],
    species = null as SpiritSpecies | null,
    evolutionStage = 1,
    animatingToNode = -1,
    battleState = 'idle' as 'idle' | 'player_attack' | 'enemy_attack' | 'enemy_defeated',
    onNodeArrived = () => {},
  }: {
    subject: string;
    nodeCount: number;
    currentNodeIndex: number;
    nodeResults: Array<boolean | null>;
    nodeHps: number[];
    nodeMaxHps: number[];
    species: SpiritSpecies | null;
    evolutionStage: number;
    animatingToNode: number;
    battleState: 'idle' | 'player_attack' | 'enemy_attack' | 'enemy_defeated';
    onNodeArrived?: () => void;
  } = $props();

  // ── Subject theming ──
  const themeColor = $derived(
    subject === 'chinese' ? '#f59e0b'
    : subject === 'math' ? '#6366f1'
    : '#a78bfa'
  );
  const themeGlow = $derived(
    subject === 'chinese' ? '#fbbf24'
    : subject === 'math' ? '#818cf8'
    : '#c4b5fd'
  );

  // ── Generate node positions (horizontal spread with slight wave) ──
  const nodePositions = $derived.by(() => {
    const positions: { x: number; y: number }[] = [];
    const totalW = 560;
    const startX = 60;
    const baseY = 130;
    const spacing = nodeCount > 1 ? totalW / (nodeCount - 1) : 0;

    for (let i = 0; i < nodeCount; i++) {
      const x = startX + i * spacing;
      // Gentle wave for visual interest
      const waveOffset = Math.sin((i / (nodeCount - 1)) * Math.PI) * 25;
      const y = baseY - waveOffset;
      positions.push({ x, y });
    }
    return positions;
  });

  // ── Current token position ──
  const activeIdx = $derived(animatingToNode >= 0 ? animatingToNode : currentNodeIndex);
  const tokenPos = $derived(nodePositions[activeIdx] ?? nodePositions[0]);
  const isMoving = $derived(animatingToNode >= 0);

  // ── Generate twinkling stars ──
  const stars = $derived.by(() => {
    const s: { x: number; y: number; size: number; delay: number; dur: number }[] = [];
    for (let i = 0; i < 60; i++) {
      s.push({
        x: Math.random() * 600,
        y: Math.random() * 220,
        size: 0.5 + Math.random() * 2,
        delay: Math.random() * 4,
        dur: 1.5 + Math.random() * 3,
      });
    }
    return s;
  });

  // ── Nebula clouds ──
  const nebulaPositions = [
    { cx: 100, cy: 80, rx: 80, ry: 40, color: '#6366f1', opacity: 0.06 },
    { cx: 350, cy: 50, rx: 100, ry: 50, color: '#a78bfa', opacity: 0.05 },
    { cx: 500, cy: 120, rx: 70, ry: 35, color: '#818cf8', opacity: 0.04 },
  ];

  // ── Build constellation path ──
  const pathD = $derived.by(() => {
    if (nodePositions.length < 2) return '';
    let d = `M ${nodePositions[0].x} ${nodePositions[0].y}`;
    for (let i = 1; i < nodePositions.length; i++) {
      d += ` L ${nodePositions[i].x} ${nodePositions[i].y}`;
    }
    return d;
  });

  // ── Monster variants per position ──
  function getMonsterVariant(index: number, total: number): { enemyType: string; variant: number } {
    if (index === total - 1) return { enemyType: 'boss', variant: 0 };
    return { enemyType: 'minion', variant: index % 3 };
  }
</script>

<div class="adventure-map w-full select-none">
  <!-- SVG Map -->
  <div class="relative rounded-2xl overflow-hidden border-2 border-indigo-900/30"
       style="background: radial-gradient(ellipse at 30% 20%, #1e1b4b 0%, #0f0d1f 40%, #020617 100%);">
    <svg
      width="600" height="240"
      viewBox="0 0 600 240"
      class="w-full h-auto"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <filter id="cosmic-glow">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <filter id="star-glow">
          <feGaussianBlur stdDeviation="1.5" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <linearGradient id="pathGrad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stop-color={themeColor} stop-opacity="0.15" />
          <stop offset="50%" stop-color={themeGlow} stop-opacity="0.5" />
          <stop offset="100%" stop-color={themeColor} stop-opacity="0.8" />
        </linearGradient>
        <radialGradient id="nodeGlow">
          <stop offset="0%" stop-color={themeGlow} stop-opacity="0.4" />
          <stop offset="100%" stop-color={themeGlow} stop-opacity="0" />
        </radialGradient>
      </defs>

      <!-- Deep space background -->
      <rect x="0" y="0" width="600" height="240" fill="transparent" />

      <!-- Nebula clouds -->
      {#each nebulaPositions as neb}
        <ellipse cx={neb.cx} cy={neb.cy} rx={neb.rx} ry={neb.ry}
                 fill={neb.color} opacity={neb.opacity} filter="url(#cosmic-glow)" />
      {/each}

      <!-- Twinkling stars -->
      {#each stars as star}
        <circle cx={star.x} cy={star.y} r={star.size}
                fill="white" opacity="0.7" filter="url(#star-glow)">
          <animate attributeName="opacity" values="0.3;1;0.3" dur="{star.dur}s"
                   begin="{star.delay}s" repeatCount="indefinite" />
        </circle>
      {/each}

      <!-- Constellation path (background glow) -->
      <path d={pathD} fill="none" stroke={themeColor} stroke-width="2"
            opacity="0.2" stroke-dasharray="8,6" filter="url(#cosmic-glow)" />

      <!-- Constellation path (main) -->
      <path d={pathD} fill="none" stroke="url(#pathGrad)" stroke-width="1.5"
            opacity="0.6" stroke-dasharray="4,8" />

      <!-- Reached path segments (lit up) -->
      {#if currentNodeIndex > 0 && nodePositions.length > 1}
        {@const reachedPts = nodePositions.slice(0, currentNodeIndex + 1)}
        {@const reachedD = reachedPts.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ')}
        <path d={reachedD} fill="none" stroke={themeGlow} stroke-width="3"
              opacity="0.9" filter="url(#cosmic-glow)" />
      {/if}

      <!-- Monster Nodes -->
      {#each nodePositions as pos, i}
        {@const monster = getMonsterVariant(i, nodeCount)}
        {@const isCurrent = i === currentNodeIndex && animatingToNode < 0}
        {@const isReached = i < currentNodeIndex}
        {@const isDefeated = nodeResults[i] === true || (isReached && nodeResults[i] !== false)}
        {@const hpPercent = nodeMaxHps[i] > 0 ? (nodeHps[i] / nodeMaxHps[i]) * 100 : 100}

        <!-- Node platform glow -->
        <circle cx={pos.x} cy={pos.y + 18} r="28" fill="url(#nodeGlow)"
                opacity={isCurrent ? 0.8 : isReached ? 0.3 : 0.15} />

        <!-- Monster sprite container -->
        <g class:opacity-25={isDefeated && !isCurrent}
           class:grayscale={isDefeated && !isCurrent}>
          <!-- EnemySprite rendered via foreignObject -->
          <foreignObject x={pos.x - 35} y={pos.y - 20} width="70" height="70">
            <div class="flex items-center justify-center w-full h-full">
              <EnemySprite
                enemyType={monster.enemyType}
                {subject}
                variant={monster.variant}
                state={isDefeated ? 'defeated'
                       : isCurrent && battleState === 'player_attack' ? 'hit'
                       : isCurrent && battleState === 'enemy_attack' ? 'attacking'
                       : isCurrent ? 'idle'
                       : 'idle'}
                size="sm"
              />
            </div>
          </foreignObject>
        </g>

        <!-- Defeated marker (stardust) -->
        {#if isDefeated && !isCurrent}
          <circle cx={pos.x} cy={pos.y + 10} r="12" fill="none" stroke={themeGlow}
                  stroke-width="1.5" opacity="0.5" stroke-dasharray="3,3" />
          <text x={pos.x} y={pos.y + 14} text-anchor="middle" font-size="14" opacity="0.7">✨</text>
        {/if}

        <!-- Current node indicator ring -->
        {#if isCurrent}
          <circle cx={pos.x} cy={pos.y + 15} r="32" fill="none" stroke={themeGlow}
                  stroke-width="2" opacity="0.6" filter="url(#cosmic-glow)">
            <animate attributeName="opacity" values="0.3;0.8;0.3" dur="2s" repeatCount="indefinite" />
            <animate attributeName="r" values="28;34;28" dur="2s" repeatCount="indefinite" />
          </circle>
        {/if}

        <!-- HP bar (current or recently active monster) -->
        {#if isCurrent || (isReached && nodeHps[i] > 0 && nodeHps[i] < nodeMaxHps[i])}
          <rect x={pos.x - 22} y={pos.y + 40} width="44" height="5" rx="2.5"
                fill="#1e293b" stroke={themeColor} stroke-width="0.5" opacity="0.7" />
          <rect x={pos.x - 22} y={pos.y + 40}
                width={Math.max(0, 44 * hpPercent / 100)} height="5" rx="2.5"
                fill={hpPercent > 50 ? themeGlow : hpPercent > 25 ? '#fbbf24' : '#f87171'}
                opacity="0.9" class="transition-all duration-500" />
        {/if}
      {/each}

      <!-- Pet Token (Spirit at current position) -->
      {#if species}
        <g class:token-moving={isMoving} class:token-idle={!isMoving}
           style="transform: translate({tokenPos.x - 18}px, {tokenPos.y - 50}px);">
          <!-- Token shadow/glow -->
          <ellipse cx="18" cy="50" rx="14" ry="4" fill={themeGlow} opacity="0.3"
                   filter="url(#cosmic-glow)" />
          <!-- Spawn indicator -->
          <circle cx="18" cy="18" r="20" fill="none" stroke={themeGlow}
                  stroke-width="1.5" opacity="0.4" filter="url(#cosmic-glow)">
            <animate attributeName="r" values="16;22;16" dur="3s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.4;0.1;0.4" dur="3s" repeatCount="indefinite" />
          </circle>
        </g>
      {/if}
    </svg>
  </div>

  <!-- Bottom legend: node progression -->
  <div class="flex justify-center gap-3 mt-2">
    {#each Array(nodeCount) as _, i}
      {@const monster = getMonsterVariant(i, nodeCount)}
      {@const isDone = i < currentNodeIndex || (i === currentNodeIndex && nodeResults[i] === true)}
      {@const isHere = i === currentNodeIndex}
      <div class="flex items-center gap-1 text-[10px] transition-all duration-300"
           class:opacity-100={isDone || isHere}
           class:opacity-35={!isDone && !isHere}
           class:scale-110={isHere}>
        <span class="text-xs">
          {isDone ? '✨' : monster.enemyType === 'boss' ? '👑' : '👾'}
        </span>
        <span class="text-gray-500 font-medium">
          {monster.enemyType === 'boss' ? 'BOSS' : i + 1}
        </span>
      </div>
    {/each}
  </div>
</div>

<style>
  :global(.token-moving) {
    transition: transform 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  :global(.token-idle) {
    animation: tokenFloat 2.5s ease-in-out infinite;
  }
  @keyframes tokenFloat {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-6px); }
  }
</style>
