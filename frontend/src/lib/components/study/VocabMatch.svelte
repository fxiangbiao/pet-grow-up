<script lang="ts">
  let {
    options,
    disabled,
    onSelect
  }: {
    options: { left: Array<{ id: string; text: string }>; right: Array<{ id: string; text: string }> };
    disabled: boolean;
    onSelect: (answer: string) => void;
  } = $props();

  let selectedLeft = $state<string | null>(null);
  let pairs = $state<Array<{ leftId: string; rightId: string }>>([]);
  let availableRight = $state<string[]>([]);

  // ── Refs for SVG line calculation ──
  let lineAreaEl = $state<HTMLDivElement | null>(null);
  let leftRefs = $state<Record<string, HTMLButtonElement>>({});
  let rightRefs = $state<Record<string, HTMLButtonElement>>({});

  $effect(() => {
    availableRight = options.right.map(r => r.id);
    selectedLeft = null;
    pairs = [];
  });

  function selectLeft(id: string) {
    if (disabled) return;
    selectedLeft = id;
  }

  function selectRight(id: string) {
    if (disabled || !selectedLeft) return;
    pairs = [...pairs, { leftId: selectedLeft, rightId: id }];
    availableRight = availableRight.filter(r => r !== id);
    selectedLeft = null;

    if (pairs.length === options.left.length) {
      const answer = pairs.map(p => `${p.leftId}${p.rightId}`).join(',');
      onSelect(answer);
    }
  }

  function resetPair() {
    if (disabled) return;
    if (pairs.length === 0) return;
    const last = pairs[pairs.length - 1];
    pairs = pairs.slice(0, -1);
    availableRight = [...availableRight, last.rightId];
  }

  function getPairedRight(leftId: string): string | undefined {
    return pairs.find(p => p.leftId === leftId)?.rightId;
  }

  function getRightText(rightId: string): string {
    return options.right.find(r => r.id === rightId)?.text || '';
  }

  // ── SVG line coordinates ──
  interface LineCoords {
    x1: number; y1: number;
    x2: number; y2: number;
    color: string;
    leftId: string;
  }

  const PAIR_COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4'];

  const lines = $derived.by((): LineCoords[] => {
    if (!lineAreaEl) return [];
    const areaRect = lineAreaEl.getBoundingClientRect();

    return pairs.map((pair, idx) => {
      const leftEl = leftRefs[pair.leftId];
      const rightEl = rightRefs[pair.rightId];
      if (!leftEl || !rightEl) return null;

      const lr = leftEl.getBoundingClientRect();
      const rr = rightEl.getBoundingClientRect();

      return {
        x1: lr.right - areaRect.left,
        y1: lr.top + lr.height / 2 - areaRect.top,
        x2: rr.left - areaRect.left,
        y2: rr.top + rr.height / 2 - areaRect.top,
        color: PAIR_COLORS[idx % PAIR_COLORS.length],
        leftId: pair.leftId,
      };
    }).filter(Boolean) as LineCoords[];
  });

  // Trigger line recalculation
  let tick = $state(0);
  $effect(() => {
    // Recalc on pair change
    if (pairs.length > 0) {
      requestAnimationFrame(() => { tick++; });
    }
  });
</script>

<div class="space-y-3">
  <div class="flex justify-between items-center">
    <span class="text-xs text-gray-400">点击左边的单词，再点击右边对应的释义</span>
    {#if pairs.length > 0}
      <button
        onclick={resetPair}
        disabled={disabled}
        class="text-xs text-gray-400 hover:text-gray-600 transition"
      >
        ↩ 撤销配对
      </button>
    {/if}
  </div>

  <div class="relative flex gap-4 justify-center items-start" bind:this={lineAreaEl}>
    <!-- Left column: English words -->
    <div class="flex flex-col gap-2 z-10">
      {#each options.left as item}
        {@const pairedRight = getPairedRight(item.id)}
        <button
          bind:this={leftRefs[item.id]}
          onclick={() => selectLeft(item.id)}
          disabled={disabled || pairedRight !== undefined}
          class={[
            'w-28 h-12 px-3 rounded-xl text-sm font-medium border-2 transition text-center flex items-center justify-center',
            pairedRight
              ? 'bg-indigo-50 border-indigo-300 text-indigo-600 cursor-default'
              : selectedLeft === item.id
                ? 'bg-indigo-100 border-indigo-500 text-indigo-700 ring-2 ring-indigo-300'
                : 'bg-white border-gray-200 text-gray-700 hover:border-indigo-300 cursor-pointer',
          ].join(' ')}
        >
          {item.text}
        </button>
      {/each}
    </div>

    <!-- Spacer for SVG lines -->
    <div class="w-16 shrink-0"></div>

    <!-- Right column: Chinese meanings -->
    <div class="flex flex-col gap-2 z-10">
      {#each options.right as item}
        <button
          bind:this={rightRefs[item.id]}
          onclick={() => selectRight(item.id)}
          disabled={disabled || !selectedLeft || !availableRight.includes(item.id)}
          class={[
            'w-28 h-12 px-3 rounded-xl text-sm font-medium border-2 transition text-center flex items-center justify-center',
            !availableRight.includes(item.id)
              ? 'bg-green-50 border-green-300 text-green-600 cursor-default'
              : selectedLeft
                ? 'bg-white border-gray-200 text-gray-700 hover:border-green-400 hover:bg-green-50 cursor-pointer'
                : 'bg-white border-gray-200 text-gray-400 cursor-default',
          ].join(' ')}
        >
          {item.text}
        </button>
      {/each}
    </div>

    <!-- SVG connection lines overlay -->
    <svg class="absolute inset-0 pointer-events-none z-20" style="width: 100%; height: 100%;">
      {#each lines as line (line.leftId)}
        <!-- Line shadow -->
        <line x1={line.x1} y1={line.y1} x2={line.x2} y2={line.y2}
          stroke={line.color} stroke-width="3" stroke-linecap="round" opacity="0.2"
          style="transform: translateY(1px);" />
        <!-- Main line -->
        <line x1={line.x1} y1={line.y1} x2={line.x2} y2={line.y2}
          stroke={line.color} stroke-width="2.5" stroke-linecap="round" opacity="0.8" />
        <!-- Start dot -->
        <circle cx={line.x1} cy={line.y1} r="4" fill={line.color} opacity="0.9" />
        <!-- End dot -->
        <circle cx={line.x2} cy={line.y2} r="4" fill={line.color} opacity="0.9" />
      {/each}
    </svg>
  </div>

  {#if pairs.length > 0 && pairs.length < options.left.length}
    <p class="text-xs text-gray-400 text-center">
      已配对 {pairs.length}/{options.left.length} 组
    </p>
  {/if}
</div>
