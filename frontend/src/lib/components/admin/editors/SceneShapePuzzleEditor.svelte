<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  // Puzzle set definitions (mirrors SceneShapePuzzle.svelte)
  const PUZZLE_SETS: Record<string, {
    label: string;
    emoji: string;
    description: string;
    pieces: { id: string; label: string; cssShape: string; color: string }[];
    targets: { id: string; cssShape: string }[];
  }> = {
    house: {
      label: '房子',
      emoji: '🏠',
      description: '正方形(房体) + 三角形(屋顶) + 长方形(门) + 圆形(窗户)',
      pieces: [
        { id: 'SQUARE', label: '正方形', cssShape: 'square', color: 'amber' },
        { id: 'TRIANGLE', label: '三角形', cssShape: 'triangle', color: 'rose' },
        { id: 'RECT', label: '长方形', cssShape: 'rectangle', color: 'emerald' },
        { id: 'CIRCLE', label: '圆形', cssShape: 'circle', color: 'sky' },
      ],
      targets: [
        { id: 'base', cssShape: 'square' },
        { id: 'roof', cssShape: 'triangle' },
        { id: 'door', cssShape: 'rectangle' },
        { id: 'window', cssShape: 'circle' },
      ],
    },
    tree: {
      label: '大树',
      emoji: '🌳',
      description: '三角形×3(树冠) + 长方形(树干)',
      pieces: [
        { id: 'TRI1', label: '三角形1', cssShape: 'triangle', color: 'emerald' },
        { id: 'TRI2', label: '三角形2', cssShape: 'triangle', color: 'teal' },
        { id: 'TRI3', label: '三角形3', cssShape: 'triangle', color: 'emerald' },
        { id: 'RECT', label: '树干', cssShape: 'rectangle', color: 'amber' },
      ],
      targets: [
        { id: 'top', cssShape: 'triangle' },
        { id: 'mid', cssShape: 'triangle' },
        { id: 'bottom', cssShape: 'triangle' },
        { id: 'trunk', cssShape: 'rectangle' },
      ],
    },
    car: {
      label: '小车',
      emoji: '🚗',
      description: '长方形(车身) + 圆形×2(车轮) + 正方形(窗户)',
      pieces: [
        { id: 'RECT1', label: '车身', cssShape: 'rectangle', color: 'sky' },
        { id: 'CIRC1', label: '车轮1', cssShape: 'circle', color: 'violet' },
        { id: 'CIRC2', label: '车轮2', cssShape: 'circle', color: 'violet' },
        { id: 'SQUARE', label: '窗户', cssShape: 'square', color: 'pink' },
      ],
      targets: [
        { id: 'body', cssShape: 'rectangle' },
        { id: 'wheel1', cssShape: 'circle' },
        { id: 'wheel2', cssShape: 'circle' },
        { id: 'window', cssShape: 'square' },
      ],
    },
  };

  const SHAPE_COLORS: Record<string, string> = {
    amber: '#fbbf24', rose: '#fb7185', emerald: '#34d399', sky: '#38bdf8',
    violet: '#a78bfa', teal: '#2dd4bf', pink: '#f472b6', orange: '#fb923c',
  };

  let selectedKey = $state('house');

  // Parse existing puzzleKey from options
  $effect(() => {
    try {
      if (questionData.options) {
        const parsed = JSON.parse(questionData.options);
        if (parsed?.puzzleKey && PUZZLE_SETS[parsed.puzzleKey]) {
          selectedKey = parsed.puzzleKey;
        }
      }
    } catch { /* ignore */ }
  });

  function selectPuzzle(key: string) {
    selectedKey = key;
    const set = PUZZLE_SETS[key];
    onUpdate?.({
      options: JSON.stringify({ puzzleKey: key }),
      correctAnswer: set.targets.map(t => t.id).join(','),
      questionText: questionData.questionText || `请把图形拼成${set.label}的样子！`,
    });
  }
</script>

<div class="space-y-4">
  <p class="text-xs text-gray-400">拼图工坊：学生拖拽图形到正确位置完成拼图</p>

  <!-- Question text -->
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder="例如：请把图形拼成房子的样子！"/>
  </div>

  <!-- Puzzle set selector -->
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-2">选择拼图模板</label>
    <div class="grid grid-cols-3 gap-3">
      {#each Object.entries(PUZZLE_SETS) as [key, set]}
        <button
          onclick={() => selectPuzzle(key)}
          class="relative p-4 rounded-xl border-2 transition-all text-left
            {selectedKey === key
              ? 'border-indigo-500 bg-indigo-50 shadow-md ring-2 ring-indigo-200'
              : 'border-gray-200 bg-white hover:border-indigo-300 hover:shadow-sm'}">
          {#if selectedKey === key}
            <span class="absolute top-2 right-2 w-5 h-5 bg-indigo-500 text-white rounded-full flex items-center justify-center text-xs">✓</span>
          {/if}
          <div class="text-2xl mb-1">{set.emoji}</div>
          <div class="text-sm font-bold text-gray-800">{set.label}</div>
          <div class="text-xs text-gray-500 mt-1 leading-tight">{set.description}</div>
          <!-- Shape preview -->
          <div class="flex flex-wrap gap-1.5 mt-3">
            {#each set.pieces as piece}
              {#if piece.cssShape === 'circle'}
                <span class="block w-5 h-5 rounded-full border" style="background:{SHAPE_COLORS[piece.color]};border-color:{SHAPE_COLORS[piece.color]}"></span>
              {:else if piece.cssShape === 'square'}
                <span class="block w-5 h-5 rounded-sm border" style="background:{SHAPE_COLORS[piece.color]};border-color:{SHAPE_COLORS[piece.color]}"></span>
              {:else if piece.cssShape === 'triangle'}
                <span class="block w-0 h-0 border-solid" style="border-left:10px solid transparent;border-right:10px solid transparent;border-bottom:18px solid {SHAPE_COLORS[piece.color]}"></span>
              {:else if piece.cssShape === 'rectangle'}
                <span class="block rounded-sm border" style="width:28px;height:14px;background:{SHAPE_COLORS[piece.color]};border-color:{SHAPE_COLORS[piece.color]}"></span>
              {/if}
            {/each}
          </div>
        </button>
      {/each}
    </div>
  </div>

  <!-- Pieces to targets mapping -->
  {#if PUZZLE_SETS[selectedKey]}
    {@const set = PUZZLE_SETS[selectedKey]}
    <div class="bg-gray-50 rounded-lg p-4 border border-gray-100">
      <h4 class="text-sm font-medium text-gray-700 mb-3">📋 拼图 → 目标位置 映射</h4>
      <div class="space-y-2">
        {#each set.targets as target, i}
          {@const piece = set.pieces[i]}
          <div class="flex items-center gap-3 text-sm">
            <span class="w-16 text-right text-gray-500 text-xs">{piece.label}</span>
            <span class="text-gray-300">→</span>
            {#if piece.cssShape === 'circle'}
              <span class="block w-4 h-4 rounded-full" style="background:{SHAPE_COLORS[piece.color]}"></span>
            {:else if piece.cssShape === 'square'}
              <span class="block w-4 h-4 rounded-sm" style="background:{SHAPE_COLORS[piece.color]}"></span>
            {:else if piece.cssShape === 'triangle'}
              <span class="block w-0 h-0 border-solid" style="border-left:8px solid transparent;border-right:8px solid transparent;border-bottom:14px solid {SHAPE_COLORS[piece.color]}"></span>
            {:else if piece.cssShape === 'rectangle'}
              <span class="block rounded-sm" style="width:22px;height:11px;background:{SHAPE_COLORS[piece.color]}"></span>
            {/if}
            <span class="text-gray-400">→</span>
            <span class="font-mono text-xs bg-white px-2 py-0.5 rounded border border-gray-200">{target.id}</span>
            <span class="text-xs text-gray-400">({target.cssShape})</span>
          </div>
        {/each}
      </div>
    </div>
  {/if}

  <!-- Generated data preview -->
  <div class="bg-amber-50 rounded-lg p-3 border border-amber-200">
    <h4 class="text-xs font-medium text-amber-700 mb-1">📦 生成数据</h4>
    <div class="text-xs font-mono text-amber-800 space-y-0.5">
      <div>options: <code>{`{"puzzleKey":"${selectedKey}"}`}</code></div>
      <div>correctAnswer: <code>{PUZZLE_SETS[selectedKey]?.targets.map(t => t.id).join(',')}</code></div>
    </div>
  </div>
</div>
