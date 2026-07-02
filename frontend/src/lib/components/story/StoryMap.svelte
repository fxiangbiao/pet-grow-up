<script lang="ts">
  import type { ChapterDTO } from '$lib/types/api';
  import type { SpiritSpecies } from '$lib/types/api';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';

  let {
    chapters = [] as ChapterDTO[],
    spiritSpecies = null as SpiritSpecies | null,
    evolutionStage = 1,
    claimingId = null as number | null,
    onChapterClick = (_ch: ChapterDTO) => {},
    onClaimReward = (_chapterId: number) => {},
  }: {
    chapters: ChapterDTO[];
    spiritSpecies: SpiritSpecies | null;
    evolutionStage: number;
    claimingId: number | null;
    onChapterClick?: (ch: ChapterDTO) => void;
    onClaimReward?: (chapterId: number) => void;
  } = $props();

  // ── NPC → subject mapping ──
  const NPC_SUBJECT_MAP: Record<string, string> = {
    '李白': 'chinese', '李清照': 'chinese',
    '智慧老人': 'math', '毕达哥拉斯': 'math',
    '梅林导师': 'english',
  };

  function getSubject(ch: ChapterDTO): string | null {
    return NPC_SUBJECT_MAP[ch.npcName] ?? null;
  }

  const subjectColors: Record<string, { glow: string; node: string; accent: string }> = {
    chinese: { glow: '#fbbf24', node: '#f59e0b', accent: '#fef3c7' },
    math: { glow: '#60a5fa', node: '#6366f1', accent: '#dbeafe' },
    english: { glow: '#c084fc', node: '#a78bfa', accent: '#f3e8ff' },
  };

  // ── Adaptive layout: compute cols/rows from chapter count ──
  const MAX_COLS = 5;
  const MIN_COLS = 3;
  const cols = $derived(Math.max(MIN_COLS, Math.min(MAX_COLS, Math.ceil(chapters.length / Math.max(1, Math.ceil(chapters.length / 4))))));
  const rows = $derived(Math.ceil(Math.max(1, chapters.length) / cols));

  // Dynamic view dimensions
  const VIEW_W = 800;
  const MARGIN_X = 90;
  const MARGIN_Y = 85;
  const ROW_SPACING = 170;
  const viewH = $derived(Math.max(400, MARGIN_Y * 2 + (rows - 1) * ROW_SPACING + 20));

  // ── Node positions (snake pattern: even rows L→R, odd rows R→L) ──
  const nodePositions = $derived.by(() => {
    const positions: { x: number; y: number; row: number }[] = [];
    const colSpacing = cols > 1 ? (VIEW_W - MARGIN_X * 2) / (cols - 1) : 0;
    for (let i = 0; i < chapters.length; i++) {
      const row = Math.floor(i / cols);
      const colInRow = i % cols;
      const col = row % 2 === 1 ? (cols - 1 - colInRow) : colInRow;
      const totalRows = Math.ceil(chapters.length / cols);
      const totalHeight = MARGIN_Y * 2 + (totalRows - 1) * ROW_SPACING;
      const startY = MARGIN_Y + (viewH - totalHeight) / 2;
      positions.push({
        x: MARGIN_X + col * colSpacing,
        y: startY + row * ROW_SPACING,
        row,
      });
    }
    return positions;
  });

  // ── Constellation path ──
  const pathD = $derived.by(() => {
    if (nodePositions.length < 2) return '';
    return nodePositions.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  });

  // ── Stars (scaled to view height) ──
  const stars = $derived.by(() => {
    const s: { x: number; y: number; r: number; delay: number; dur: number }[] = [];
    const count = Math.floor(viewH * 0.15);
    for (let i = 0; i < count; i++) {
      s.push({
        x: Math.random() * VIEW_W,
        y: Math.random() * viewH,
        r: 0.4 + Math.random() * 1.8,
        delay: Math.random() * 5,
        dur: 1.5 + Math.random() * 4,
      });
    }
    return s;
  });

  // ── Subject region nebulas (one per row) ──
  const nebulas = $derived.by(() => {
    const nebs: { cx: number; cy: number; rx: number; ry: number; color: string; opacity: number }[] = [];
    const nebColors = ['#fbbf24', '#60a5fa', '#c084fc', '#fbbf24', '#60a5fa', '#c084fc'];
    for (let r = 0; r < rows; r++) {
      if (nodePositions.length > 0) {
        const rowNodes = nodePositions.filter(p => p.row === r);
        if (rowNodes.length > 0) {
          const cy = rowNodes[0].y - 10;
          nebs.push({
            cx: VIEW_W / 2,
            cy,
            rx: VIEW_W * 0.38,
            ry: 50,
            color: nebColors[r % nebColors.length],
            opacity: 0.04,
          });
        }
      }
    }
    return nebs;
  });

  // ── Region labels ──
  const regionLabels = [
    { text: '📜 诗词大陆', color: '#fbbf24' },
    { text: '🔢 智慧王国', color: '#60a5fa' },
    { text: '🔤 魔法学院', color: '#c084fc' },
  ];

  const rowLabels = $derived.by(() => {
    const labels: { y: number; text: string; color: string }[] = [];
    for (let r = 0; r < rows; r++) {
      const rowNodes = nodePositions.filter(p => p.row === r);
      if (rowNodes.length > 0) {
        const label = regionLabels[r % regionLabels.length];
        labels.push({
          y: rowNodes[0].y - 52,
          text: label.text,
          color: label.color,
        });
      }
    }
    return labels;
  });

  // ── Current spirit position ──
  const currentIdx = $derived(chapters.findIndex(c => c.unlocked && !c.completed));
  const spiritPos = $derived(currentIdx >= 0 ? nodePositions[currentIdx] : null);

  function getChapterStatus(ch: ChapterDTO): 'completed' | 'current' | 'locked' {
    if (ch.completed) return 'completed';
    if (ch.unlocked) return 'current';
    return 'locked';
  }
</script>

<div class="story-map w-full select-none">
  <div class="relative rounded-2xl overflow-hidden border-2 border-indigo-900/30"
       style="background: radial-gradient(ellipse at 40% 20%, #1e1b4b 0%, #0f0d1f 45%, #020617 100%);">
    <svg
      width={VIEW_W} height={viewH}
      viewBox="0 0 {VIEW_W} {viewH}"
      class="w-full h-auto"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <filter id="sm-cosmic-glow">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <filter id="sm-star-glow">
          <feGaussianBlur stdDeviation="1.2" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <filter id="sm-node-glow">
          <feGaussianBlur stdDeviation="4" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <linearGradient id="smPathGrad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stop-color="#6366f1" stop-opacity="0.1" />
          <stop offset="50%" stop-color="#a78bfa" stop-opacity="0.5" />
          <stop offset="100%" stop-color="#6366f1" stop-opacity="0.8" />
        </linearGradient>
      </defs>

      <!-- Deep space bg -->
      <rect x="0" y="0" width={VIEW_W} height={viewH} fill="transparent" />

      <!-- Nebula clouds per region -->
      {#each nebulas as neb}
        <ellipse cx={neb.cx} cy={neb.cy} rx={neb.rx} ry={neb.ry}
                 fill={neb.color} opacity={neb.opacity} filter="url(#sm-cosmic-glow)" />
      {/each}

      <!-- Twinkling stars -->
      {#each stars as star}
        <circle cx={star.x} cy={star.y} r={star.r} fill="white" opacity="0.6" filter="url(#sm-star-glow)">
          <animate attributeName="opacity" values="0.2;0.9;0.2" dur="{star.dur}s"
                   begin="{star.delay}s" repeatCount="indefinite" />
        </circle>
      {/each}

      <!-- Region labels -->
      {#each rowLabels as region}
        <text x={VIEW_W / 2} y={region.y} text-anchor="middle"
              fill={region.color} font-size="13" font-weight="600"
              opacity="0.45" filter="url(#sm-cosmic-glow)">{region.text}</text>
      {/each}

      <!-- Constellation path (background glow) -->
      <path d={pathD} fill="none" stroke="#6366f1" stroke-width="2.5"
            opacity="0.15" stroke-dasharray="10,8" filter="url(#sm-cosmic-glow)" />

      <!-- Constellation path (main) -->
      <path d={pathD} fill="none" stroke="url(#smPathGrad)" stroke-width="1.5"
            opacity="0.5" stroke-dasharray="5,10" />

      <!-- Reached path segments (lit up) -->
      {#if currentIdx > 0}
        {@const reachedPts = nodePositions.slice(0, currentIdx + 1)}
        {@const reachedD = reachedPts.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ')}
        <path d={reachedD} fill="none" stroke="#a78bfa" stroke-width="3"
              opacity="0.7" filter="url(#sm-cosmic-glow)" />
      {/if}

      <!-- Chapter Nodes -->
      {#each chapters as ch, i}
        {@const pos = nodePositions[i]}
        {#if pos}
          {@const status = getChapterStatus(ch)}
          {@const subj = getSubject(ch)}
          {@const colors = subj ? subjectColors[subj] : subjectColors.english}
          {@const isCurrent = status === 'current'}
          {@const isCompleted = status === 'completed'}
          {@const isLocked = status === 'locked'}

          <!-- Node platform glow -->
          <circle cx={pos.x} cy={pos.y} r="30" fill={colors.glow}
                  opacity={isCurrent ? 0.25 : isCompleted ? 0.15 : 0.05}
                  filter="url(#sm-cosmic-glow)" />

          <!-- Node circle -->
          <circle cx={pos.x} cy={pos.y} r="16"
                  fill={isLocked ? '#1e293b' : isCompleted ? '#065f46' : colors.node}
                  stroke={isLocked ? '#475569' : isCompleted ? '#34d399' : colors.glow}
                  stroke-width={isCurrent ? 2.5 : 1.5}
                  opacity={isLocked ? 0.5 : 1}
                  filter="url(#sm-node-glow)"
                  class="cursor-pointer transition-all duration-300 hover:brightness-125" />

          <!-- Chapter number or checkmark -->
          <text x={pos.x} y={pos.y + 1} text-anchor="middle" dominant-baseline="central"
                fill={isLocked ? '#64748b' : 'white'}
                font-size={isCompleted ? '12' : '11'} font-weight="bold"
                class:opacity-50={isLocked}>
            {isCompleted ? '✓' : ch.chapterNumber}
          </text>

          <!-- Current node pulse ring -->
          {#if isCurrent}
            <circle cx={pos.x} cy={pos.y} r="22" fill="none" stroke={colors.glow}
                    stroke-width="2" opacity="0.5" filter="url(#sm-cosmic-glow)">
              <animate attributeName="opacity" values="0.2;0.7;0.2" dur="2.2s" repeatCount="indefinite" />
              <animate attributeName="r" values="18;24;18" dur="2.2s" repeatCount="indefinite" />
            </circle>
          {/if}

          <!-- Chapter title label -->
          <text x={pos.x} y={pos.y + 32} text-anchor="middle"
                fill={isLocked ? '#475569' : isCompleted ? '#6ee7b7' : '#cbd5e1'}
                font-size="9" font-weight="500"
                class:opacity-60={isLocked}>
            {ch.title.length > 6 ? ch.title.slice(0, 6) + '…' : ch.title}
          </text>

          <!-- Reward badge (completed, unclaimed) -->
          {#if isCompleted && !ch.rewardClaimed}
            <g transform="translate({pos.x + 15}, {pos.y - 18})">
              <circle r="10" fill="#f59e0b" opacity="0.9" />
              <text y="1" text-anchor="middle" dominant-baseline="central" font-size="10">⚡</text>
            </g>
          {/if}

          <!-- Locked indicator -->
          {#if isLocked}
            <text x={pos.x + 14} y={pos.y - 14} font-size="8" opacity="0.5">🔒</text>
          {/if}

          <!-- Invisible click target -->
          <circle cx={pos.x} cy={pos.y} r="28" fill="transparent"
                  class="cursor-pointer"
                  onclick={() => { if (!isLocked) onChapterClick(ch); }} />
        {/if}
      {/each}

      <!-- Spirit avatar at current chapter -->
      {#if spiritSpecies && spiritPos}
        <g transform="translate({spiritPos.x - 15}, {spiritPos.y - 52})">
          <ellipse cx="15" cy="52" rx="12" ry="3.5" fill="#a78bfa" opacity="0.25"
                   filter="url(#sm-cosmic-glow)" />
          <circle cx="15" cy="15" r="18" fill="none" stroke="#a78bfa"
                  stroke-width="1.5" opacity="0.35" filter="url(#sm-cosmic-glow)">
            <animate attributeName="r" values="14;20;14" dur="3s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.35;0.08;0.35" dur="3s" repeatCount="indefinite" />
          </circle>
          <foreignObject x="0" y="0" width="30" height="30">
            <div class="w-full h-full rounded-full overflow-hidden"
                 style="box-shadow: 0 0 10px rgba(167, 139, 250, 0.4);">
              <SpiritAvatar species={spiritSpecies} {evolutionStage} mood="happy" size="sm" />
            </div>
          </foreignObject>
        </g>
      {/if}
    </svg>
  </div>
</div>
