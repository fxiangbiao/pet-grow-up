<script lang="ts">
  import { submitAnswer, type QuestionDTO, type AnswerResult } from '$lib/api/study';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    question,
    sessionId,
    onComplete
  }: {
    question: QuestionDTO;
    sessionId: number;
    onComplete: (result: AnswerResult) => void;
  } = $props();

  // ── Shape definitions ──
  interface ShapePiece {
    id: string;
    label: string;
    cssShape: 'circle' | 'square' | 'triangle' | 'rectangle';
    color: string; // Tailwind bg class suffix
  }

  interface TargetSlot {
    id: string;
    cssShape: 'circle' | 'square' | 'triangle' | 'rectangle';
    filled: boolean;
    filledById: string | null;
  }

  // Predefined puzzle sets
  const PUZZLE_SETS: Record<string, { pieces: ShapePiece[]; targets: TargetSlot[] }> = {
    house: {
      pieces: [
        { id: 'SQUARE', label: '正方形', cssShape: 'square', color: 'amber' },
        { id: 'TRIANGLE', label: '三角形', cssShape: 'triangle', color: 'rose' },
        { id: 'RECT', label: '长方形', cssShape: 'rectangle', color: 'emerald' },
        { id: 'CIRCLE', label: '圆形', cssShape: 'circle', color: 'sky' },
      ],
      targets: [
        { id: 'base', cssShape: 'square', filled: false, filledById: null },
        { id: 'roof', cssShape: 'triangle', filled: false, filledById: null },
        { id: 'door', cssShape: 'rectangle', filled: false, filledById: null },
        { id: 'window', cssShape: 'circle', filled: false, filledById: null },
      ],
    },
    tree: {
      pieces: [
        { id: 'TRI1', label: '三角形1', cssShape: 'triangle', color: 'emerald' },
        { id: 'TRI2', label: '三角形2', cssShape: 'triangle', color: 'teal' },
        { id: 'TRI3', label: '三角形3', cssShape: 'triangle', color: 'emerald' },
        { id: 'RECT', label: '树干', cssShape: 'rectangle', color: 'amber' },
      ],
      targets: [
        { id: 'top', cssShape: 'triangle', filled: false, filledById: null },
        { id: 'mid', cssShape: 'triangle', filled: false, filledById: null },
        { id: 'bottom', cssShape: 'triangle', filled: false, filledById: null },
        { id: 'trunk', cssShape: 'rectangle', filled: false, filledById: null },
      ],
    },
    car: {
      pieces: [
        { id: 'RECT1', label: '车身', cssShape: 'rectangle', color: 'sky' },
        { id: 'CIRC1', label: '车轮1', cssShape: 'circle', color: 'violet' },
        { id: 'CIRC2', label: '车轮2', cssShape: 'circle', color: 'violet' },
        { id: 'SQUARE', label: '窗户', cssShape: 'square', color: 'pink' },
      ],
      targets: [
        { id: 'body', cssShape: 'rectangle', filled: false, filledById: null },
        { id: 'wheel1', cssShape: 'circle', filled: false, filledById: null },
        { id: 'wheel2', cssShape: 'circle', filled: false, filledById: null },
        { id: 'window', cssShape: 'square', filled: false, filledById: null },
      ],
    },
  };

  // JIT-safe color maps
  const SHAPE_FILL: Record<string, string> = {
    amber: 'bg-amber-400 border-amber-600',
    rose: 'bg-rose-400 border-rose-600',
    emerald: 'bg-emerald-400 border-emerald-600',
    sky: 'bg-sky-400 border-sky-600',
    violet: 'bg-violet-400 border-violet-600',
    teal: 'bg-teal-400 border-teal-600',
    pink: 'bg-pink-400 border-pink-600',
    orange: 'bg-orange-400 border-orange-600',
  };
  const TRIANGLE_COLOR: Record<string, string> = {
    amber: '#fbbf24', rose: '#fb7185', emerald: '#34d399', sky: '#38bdf8',
    violet: '#a78bfa', teal: '#2dd4bf', pink: '#f472b6', orange: '#fb923c',
  };

  // Parse puzzle from question options or pick random
  function parsePuzzleKey(raw: string | null): string {
    const keys = Object.keys(PUZZLE_SETS);
    if (!raw) return keys[Math.floor(Math.random() * keys.length)];
    try {
      const parsed = JSON.parse(raw);
      if (parsed?.puzzleKey && PUZZLE_SETS[parsed.puzzleKey]) return parsed.puzzleKey;
    } catch { /* fall through */ }
    if (typeof raw === 'object' && raw !== null) {
      const o = raw as any;
      if (o.puzzleKey && PUZZLE_SETS[o.puzzleKey]) return o.puzzleKey;
    }
    return keys[Math.floor(Math.random() * keys.length)];
  }

  const puzzleKey = $state(parsePuzzleKey(question.options as string | null));
  const puzzle = $derived(PUZZLE_SETS[puzzleKey] || PUZZLE_SETS.house);

  let pieces = $state<ShapePiece[]>([]);
  let targets = $state<TargetSlot[]>([]);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);

  // Init
  $effect(() => {
    pieces = [...puzzle.pieces].sort(() => Math.random() - 0.5);
    targets = puzzle.targets.map(t => ({ ...t, filled: false, filledById: null }));
  });

  // ── Drag and drop ──
  let dragPieceId = $state<string | null>(null);
  let dragOverSlotId = $state<string | null>(null);

  function handleDragStart(pieceId: string) {
    if (submitted) return;
    dragPieceId = pieceId;
  }

  function handleDragOver(e: DragEvent, slotId: string) {
    e.preventDefault();
    if (submitted) return;
    dragOverSlotId = slotId;
  }

  function handleDrop(slotId: string) {
    dragOverSlotId = null;
    if (!dragPieceId || submitted) return;

    const target = targets.find(t => t.id === slotId);
    if (!target || target.filled) return;

    const piece = pieces.find(p => p.id === dragPieceId);
    if (!piece) return;

    // Check if shape matches
    if (piece.cssShape !== target.cssShape) {
      soundManager.playWrong();
      dragPieceId = null;
      return;
    }

    // Snap!
    target.filled = true;
    target.filledById = piece.id;
    pieces = pieces.filter(p => p.id !== piece.id);
    soundManager.playPuzzleSnap();
    dragPieceId = null;

    // Check if all filled
    if (targets.every(t => t.filled)) {
      handleAllFilled();
    }
  }

  function handleDragEnd() {
    dragPieceId = null;
    dragOverSlotId = null;
  }

  // For touch devices: click-based placement
  let selectedPieceId = $state<string | null>(null);

  function selectPiece(pieceId: string) {
    if (submitted) return;
    selectedPieceId = pieceId === selectedPieceId ? null : pieceId;
  }

  function tapSlot(slotId: string) {
    if (!selectedPieceId || submitted) return;

    const target = targets.find(t => t.id === slotId);
    if (!target || target.filled) return;

    const piece = puzzle.pieces.find(p => p.id === selectedPieceId);
    if (!piece || piece.cssShape !== target.cssShape) {
      soundManager.playWrong();
      selectedPieceId = null;
      return;
    }

    target.filled = true;
    target.filledById = piece.id;
    pieces = pieces.filter(p => p.id !== piece.id);
    soundManager.playPuzzleSnap();
    selectedPieceId = null;

    if (targets.every(t => t.filled)) {
      handleAllFilled();
    }
  }

  async function handleAllFilled() {
    submitted = true;
    try {
      // Auto-submit with all slots filled correctly
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: targets.map(t => t.filledById).join(','),
        timeSpent: 0
      });
      if (result) {
        feedback = 'correct';
        showFeedback = true;
        soundManager.playCelebrate();
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('[ShapePuzzle] onComplete failed:', e); }
        }, 1500);
      }
    } catch (err) {
      console.error('[ShapePuzzle] Submit failed:', err);
      submitted = false;
      targets.forEach(t => { t.filled = false; t.filledById = null; });
      pieces = [...puzzle.pieces].sort(() => Math.random() - 0.5);
    }
  }

  // Default puzzle if parsing fails (house)
  const PUZZLE_NAMES: Record<string, string> = { house: '🏠 房子', tree: '🌳 大树', car: '🚗 小车' };
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-amber-50 to-orange-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="图形拼图"
>
  <!-- Hint -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-orange-800 bg-white/80 rounded-full px-5 py-1.5 shadow-sm">
      🐱「{question.questionText || '把图形拖到正确的位置吧！'}」{PUZZLE_NAMES[puzzleKey] || ''}
    </p>
  </div>

  <!-- Main area: pieces (left) + target (right) -->
  <div class="absolute inset-x-0 top-16 bottom-8 flex gap-4 px-4">
    <!-- Piece library -->
    <div class="w-1/3 flex flex-col items-center justify-center gap-3 p-2">
      <p class="text-xs text-gray-500 font-medium mb-1">图形库</p>
      {#each pieces as piece (piece.id)}
        <div
          draggable="true"
          ondragstart={() => handleDragStart(piece.id)}
          ondragend={handleDragEnd}
          onclick={() => selectPiece(piece.id)}
          class={[
            'w-16 h-16 flex items-center justify-center rounded-xl border-2 transition-all duration-200',
            'cursor-grab active:cursor-grabbing shadow-md',
            selectedPieceId === piece.id ? 'ring-3 ring-blue-400 scale-110' : 'hover:scale-105',
          ].join(' ')}
          aria-label={piece.label}
        >
          {#if piece.cssShape === 'circle'}
            <span class="block w-12 h-12 rounded-full border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'}"></span>
          {:else if piece.cssShape === 'square'}
            <span class="block w-12 h-12 rounded-md border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'}"></span>
          {:else if piece.cssShape === 'triangle'}
            <span class="block w-0 h-0 border-solid"
              style="border-left: 24px solid transparent; border-right: 24px solid transparent; border-bottom: 40px solid {TRIANGLE_COLOR[piece.color] || '#9ca3af'}; filter: drop-shadow(0 2px 2px rgb(0 0 0 / 0.15));"
            ></span>
          {:else if piece.cssShape === 'rectangle'}
            <span class="block rounded-md border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'}"
              style="width: 48px; height: 28px;"
            ></span>
          {/if}
        </div>
      {/each}
    </div>

    <!-- Target area -->
    <div class="w-2/3 flex-1 relative bg-white/60 rounded-2xl border-2 border-dashed border-amber-300 p-4 flex items-center justify-center">
      <p class="absolute top-2 left-1/2 -translate-x-1/2 text-xs text-gray-400">拖放到这里</p>
      <div class="flex flex-wrap items-end justify-center gap-3">
        {#each targets as slot (slot.id)}
          <div
            ondrop={(e: DragEvent) => handleDrop(slot.id)}
            ondragover={(e: DragEvent) => handleDragOver(e, slot.id)}
            ondragleave={() => { dragOverSlotId = null; }}
            onclick={() => tapSlot(slot.id)}
            class={[
              'flex items-center justify-center rounded-xl border-2 border-dashed transition-all duration-300',
              slot.filled ? 'border-green-400 bg-green-50' : 'border-gray-300 hover:border-amber-400',
              dragOverSlotId === slot.id ? 'border-blue-400 bg-blue-50 scale-105' : '',
              !slot.filled ? 'cursor-pointer' : '',
            ].join(' ')}
            style={slot.cssShape === 'rectangle' || slot.cssShape === 'square'
              ? 'width: 64px; height: 64px;'
              : 'width: 64px; height: 64px;'}
            aria-label={'放置区 ' + slot.cssShape}
          >
            {#if slot.filled}
              {@const piece = puzzle.pieces.find(p => p.id === slot.filledById)}
              {#if piece}
                {#if piece.cssShape === 'circle'}
                  <span class="block w-11 h-11 rounded-full border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'} animate-bounce-in"></span>
                {:else if piece.cssShape === 'square'}
                  <span class="block w-11 h-11 rounded-md border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'} animate-bounce-in"></span>
                {:else if piece.cssShape === 'triangle'}
                  <span class="block w-0 h-0 border-solid animate-bounce-in"
                    style="border-left: 22px solid transparent; border-right: 22px solid transparent; border-bottom: 38px solid {TRIANGLE_COLOR[piece.color] || '#9ca3af'}; filter: drop-shadow(0 2px 2px rgb(0 0 0 / 0.15));"
                  ></span>
                {:else if piece.cssShape === 'rectangle'}
                  <span class="block rounded-md border-2 shadow-inner {SHAPE_FILL[piece.color] || 'bg-gray-400 border-gray-600'} animate-bounce-in"
                    style="width: 44px; height: 26px;"
                  ></span>
                {/if}
              {/if}
            {:else}
              <span class="text-2xl text-gray-300">
                {slot.cssShape === 'circle' ? '○' : slot.cssShape === 'square' ? '□' : slot.cssShape === 'triangle' ? '△' : '▭'}
              </span>
            {/if}
          </div>
        {/each}
      </div>
    </div>
  </div>

  <!-- Feedback overlay -->
  {#if showFeedback}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in">
        🎉 拼好啦！
      </div>
    </div>
  {/if}
</div>

<style lang="postcss">
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    50% { transform: scale(1.1); }
    70% { transform: scale(0.9); }
    100% { transform: scale(1); opacity: 1; }
  }
  :global(.animate-bounce-in) {
    animation: bounceIn 0.5s ease-out;
  }
</style>
