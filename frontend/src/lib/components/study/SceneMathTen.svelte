<script lang="ts">
  import { submitAnswer, type QuestionDTO, type AnswerResult } from '$lib/api/study';

  let {
    question,
    sessionId,
    onComplete
  }: {
    question: QuestionDTO;
    sessionId: number;
    onComplete: (result: AnswerResult) => void;
  } = $props();

  const target = 10;

  function parseQuestion(qText: string): { needed: number; parseOk: boolean } {
    let m = qText.match(/(\d+)\s*\+\s*[？?]\s*=\s*(\d+)/);
    if (m) {
      const start = parseInt(m[1]);
      const tgt = parseInt(m[2]);
      const n = tgt - start;
      if (n > 0 && n <= tgt) return { needed: n, parseOk: true };
    }
    m = qText.match(/[？?]\s*\+\s*(\d+)\s*=\s*(\d+)/);
    if (m) {
      const start = parseInt(m[1]);
      const tgt = parseInt(m[2]);
      const n = tgt - start;
      if (n > 0 && n <= tgt) return { needed: n, parseOk: true };
    }
    m = qText.match(/拖\s*(\d+)/);
    if (m) return { needed: parseInt(m[1]), parseOk: true };

    return { needed: 5, parseOk: false };
  }

  // ═══ State ═══
  let needed = $state(5);
  let parseOk = $state(false);
  let apples = $state<Array<{ id: number; x: number; y: number; inBowl: boolean }>>([]);
  let bowlCount = $state(0);
  let dragging = $state<number | null>(null);
  let dragX = $state(0);
  let dragY = $state(0);
  let feedback = $state<'idle' | 'correct' | 'tooMany'>('idle');
  let showFeedback = $state(false);
  let submitted = $state(false);
  let containerEl = $state<HTMLDivElement | null>(null);
  let bowlOccupants = $state<number[]>(Array(10).fill(-1));
  let pointerMoved = $state(false);
  let pointerStartX = $state(0);
  let pointerStartY = $state(0);

  // Slot positions relative to bowl center
  const bowlSlots = [
    { x: 30, y: 82 }, { x: 60, y: 85 }, { x: 90, y: 82 }, { x: 120, y: 78 },
    { x: 42, y: 58 }, { x: 72, y: 56 }, { x: 105, y: 54 },
    { x: 52, y: 34 }, { x: 90, y: 32 },
    { x: 72, y: 14 },
  ];

  const totalApples = $derived(Math.max(needed, Math.min(target, 10)));

  function initApples() {
    apples = Array.from({ length: totalApples }, (_, i) => ({
      id: i,
      x: 15 + Math.random() * 70,
      y: 10 + Math.random() * 50,
      inBowl: false
    }));
    bowlCount = 0;
    bowlOccupants = Array(10).fill(-1);
    feedback = 'idle';
    showFeedback = false;
    submitted = false;
  }

  // Parse question & init apples on mount.
  // Parent {#key question.questionId} forces remount on question change.
  const qText = question.questionText || '';
  const parsed = parseQuestion(qText);
  needed = parsed.needed;
  parseOk = parsed.parseOk;
  initApples();

  // ── Drag handlers ──

  function handlePointerDown(id: number, e: PointerEvent) {
    if (submitted) return;
    dragging = id;
    pointerMoved = false;
    pointerStartX = e.clientX;
    pointerStartY = e.clientY;
    const rect = containerEl?.getBoundingClientRect();
    dragX = e.clientX - (rect?.left ?? 0);
    dragY = e.clientY - (rect?.top ?? 0);
    (e.target as HTMLElement)?.setPointerCapture?.(e.pointerId);
  }

  function handlePointerMove(e: PointerEvent) {
    if (dragging === null) return;
    const dx = e.clientX - pointerStartX;
    const dy = e.clientY - pointerStartY;
    if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
      pointerMoved = true;
    }
    const rect = containerEl?.getBoundingClientRect();
    dragX = e.clientX - (rect?.left ?? 0);
    dragY = e.clientY - (rect?.top ?? 0);
  }

  function handlePointerUp() {
    if (dragging === null || submitted) return;

    if (!pointerMoved) {
      // Tap-to-add: auto-add apple to bowl
      const apple = apples.find(a => a.id === dragging);
      if (apple && !apple.inBowl) {
        addAppleToBowl(apple);
      }
      dragging = null;
      return;
    }

    // Drag-to-bowl: check drop zone
    const bowlEl = document.getElementById('bowl-zone');
    const containerRect = containerEl?.getBoundingClientRect();
    if (bowlEl && containerRect) {
      const bowlRect = bowlEl.getBoundingClientRect();
      const bowlLeft = bowlRect.left - containerRect.left;
      const bowlRight = bowlRect.right - containerRect.left;
      const bowlTop = bowlRect.top - containerRect.top;
      const bowlBottom = bowlRect.bottom - containerRect.top;
      if (dragX > bowlLeft && dragX < bowlRight && dragY > bowlTop && dragY < bowlBottom) {
        const apple = apples.find(a => a.id === dragging);
        if (apple && !apple.inBowl) {
          addAppleToBowl(apple);
        }
      }
    }
    dragging = null;
  }

  function addAppleToBowl(apple: { id: number; x: number; y: number; inBowl: boolean }) {
    const slotIndex = bowlOccupants.findIndex(o => o === -1);
    if (slotIndex < 0) return;
    apple.inBowl = true;
    bowlOccupants[slotIndex] = apple.id;
    bowlCount++;

    if (bowlCount === needed) {
      feedback = 'correct';
      showFeedback = true;
      submitted = true;
      doSubmit();
    } else if (bowlCount > needed) {
      feedback = 'tooMany';
      showFeedback = true;
      bowlCount--;
      apple.inBowl = false;
      bowlOccupants[slotIndex] = -1;
      setTimeout(() => { showFeedback = false; feedback = 'idle'; }, 1000);
    }
  }

  async function doSubmit() {
    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: String(bowlCount),
        timeSpent: 0
      });
      if (result) {
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('onComplete failed:', e); }
        }, 1500);
      } else {
        throw new Error('Empty API result');
      }
    } catch (err) {
      console.error('[SceneMathTen] Submit failed:', err);
      submitted = false;
      feedback = 'idle';
      showFeedback = false;
      bowlCount = 0;
      initApples();
    }
  }
</script>

<div
  class="relative w-full min-h-[480px] bg-gradient-to-b from-amber-50 to-orange-100 overflow-hidden select-none rounded-xl"
  style="touch-action: none;"
  onpointermove={handlePointerMove}
  onpointerup={handlePointerUp}
  bind:this={containerEl}
  role="application"
  aria-label="拖苹果凑十法游戏"
>
  <!-- Pet hint banner -->
  <div class="absolute top-4 left-1/2 -translate-x-1/2 text-center z-10">
    {#if parseOk}
      <p class="text-lg font-bold text-amber-800 bg-white/80 rounded-full px-6 py-2 shadow-sm">
        🐱「帮我凑 {needed} 个苹果到碗里！」
      </p>
      <p class="text-sm text-amber-600 mt-1">碗里：{bowlCount}/{needed}</p>
    {:else}
      <p class="text-lg font-bold text-amber-800 bg-white/80 rounded-full px-6 py-2 shadow-sm">
        🐱「拖苹果到碗里吧！」
      </p>
      <p class="text-sm text-amber-600 mt-1">碗里：{bowlCount}</p>
      <p class="text-xs text-red-500 mt-1">（题目解析异常，请拖放任意数量苹果后自动提交）</p>
    {/if}
  </div>

  <!-- Draggable apples -->
  {#each apples.filter(a => !a.inBowl) as apple (apple.id)}
    <div
      class="absolute w-12 h-12 flex items-center justify-center text-3xl cursor-grab active:cursor-grabbing
        {dragging === apple.id ? 'scale-125 z-20' : 'hover:scale-110'} transition-transform"
      style="left: {apple.x}%; top: {apple.y}%; touch-action: none;"
      onpointerdown={(e) => handlePointerDown(apple.id, e)}
      role="button"
      tabindex="0"
    >
      🍎
    </div>
  {/each}

  <!-- Drag-following ghost apple -->
  {#if dragging !== null && !apples.find(a => a.id === dragging)?.inBowl}
    <div
      class="absolute w-14 h-14 flex items-center justify-center text-4xl z-30 pointer-events-none drop-shadow-lg"
      style="left: {dragX - 28}px; top: {dragY - 28}px;"
    >
      🍎
    </div>
  {/if}

  <!-- Bowl drop zone -->
  <div
    id="bowl-zone"
    class="absolute bottom-8 left-1/2 -translate-x-1/2 w-44 h-32 flex flex-col items-center justify-end
      border-4 border-dashed rounded-b-[80px] transition-all duration-300
      {bowlCount === needed ? 'border-green-400 bg-green-100/40' : ''}
      {bowlCount > 0 && bowlCount < needed ? 'border-amber-400 bg-amber-50/40' : ''}
      {bowlCount === 0 ? 'border-gray-400 bg-white/30' : ''}"
  >
    {#each bowlSlots as slot, i}
      {#if bowlOccupants[i] === -1}
        <div
          class="absolute w-6 h-6 rounded-full border border-dashed border-gray-300/50"
          style="left: {slot.x - 12}px; top: {slot.y - 12}px;"
        ></div>
      {/if}
    {/each}
    {#each bowlSlots as slot, i}
      {#if bowlOccupants[i] !== -1}
        <div
          class="absolute w-10 h-10 flex items-center justify-center text-2xl z-5 pointer-events-none animate-bounce-in"
          style="left: {slot.x - 20}px; top: {slot.y - 20}px; animation-duration: 0.35s;"
        >
          🍎
        </div>
      {/if}
    {/each}

    <span class="text-5xl mb-1 relative z-0">🥣</span>
    <span class="text-xs text-gray-500 mb-1">拖放或点击苹果</span>
  </div>

  <!-- Feedback overlay -->
  {#if showFeedback}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      {#if feedback === 'correct'}
        <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in">
          ✅ 凑满 {target} 啦！
        </div>
      {:else if feedback === 'tooMany'}
        <div class="bg-amber-500 text-white text-xl font-bold px-6 py-3 rounded-2xl shadow-xl animate-shake">
          ⚠️ 太多啦！只要 {needed} 个～
        </div>
      {/if}
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
  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    20% { transform: translateX(-8px); }
    40% { transform: translateX(8px); }
    60% { transform: translateX(-4px); }
    80% { transform: translateX(4px); }
  }
  :global(.animate-shake) {
    animation: shake 0.4s ease-out;
  }
</style>
