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

  // Parse "凑十法：8 + ? = 10" → start=8, target=10, needed=2
  const target = 10;
  const start = parseInt(question.questionText.match(/(\d+)\s*\+/)?.[1] || '0');
  const needed = target - start;

  // Slot positions relative to bowl center (bowl is 160×112, center at 80,56)
  // Arranged bottom-to-top for natural pile look
  const bowlSlots = [
    { x: 30, y: 82 }, { x: 60, y: 85 }, { x: 90, y: 82 }, { x: 120, y: 78 },  // bottom row
    { x: 42, y: 58 }, { x: 72, y: 56 }, { x: 105, y: 54 },                       // middle row
    { x: 52, y: 34 }, { x: 90, y: 32 },                                           // upper row
    { x: 72, y: 14 },                                                              // top
  ];

  // Scene state
  let apples = $state<Array<{ id: number; x: number; y: number; inBowl: boolean }>>([]);
  let bowlCount = $state(0);
  let dragging = $state<number | null>(null);
  let dragX = $state(0);
  let dragY = $state(0);
  let feedback = $state<'idle' | 'correct' | 'tooMany'>('idle');
  let showFeedback = $state(false);
  let submitted = $state(false);
  let containerEl = $state<HTMLDivElement | null>(null);
  // Which apple occupies each bowl slot (-1 = empty)
  let bowlOccupants = $state<number[]>(Array(10).fill(-1));

  function initApples() {
    apples = Array.from({ length: target }, (_, i) => ({
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
  initApples();

  // Drag handlers
  function handlePointerDown(id: number, e: PointerEvent) {
    if (submitted) return;
    dragging = id;
    const rect = containerEl?.getBoundingClientRect();
    dragX = e.clientX - (rect?.left ?? 0);
    dragY = e.clientY - (rect?.top ?? 0);
    (e.target as HTMLElement)?.setPointerCapture?.(e.pointerId);
  }

  function handlePointerMove(e: PointerEvent) {
    if (dragging === null) return;
    const rect = containerEl?.getBoundingClientRect();
    dragX = e.clientX - (rect?.left ?? 0);
    dragY = e.clientY - (rect?.top ?? 0);
  }

  function handlePointerUp() {
    if (dragging === null || submitted) return;
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
          const slotIndex = bowlOccupants.findIndex(o => o === -1);
          if (slotIndex >= 0) {
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
        }
      }
    }
    dragging = null;
  }

  async function doSubmit() {
    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: String(needed),
        timeSpent: 0
      });
      if (result) {
        setTimeout(() => {
          try {
            onComplete(result);
          } catch (callbackErr) {
            console.error('onComplete callback failed:', callbackErr);
            // Force reset on callback failure
            submitted = false;
            feedback = 'idle';
            showFeedback = false;
            bowlCount = 0;
            initApples();
          }
        }, 1500);
      } else {
        throw new Error('Empty result from API');
      }
    } catch (err) {
      console.error('Submit failed, resetting:', err);
      submitted = false;
      feedback = 'idle';
      showFeedback = false;
      bowlCount = 0;
      initApples();
    }
  }
</script>

<div
  class="relative w-full h-full min-h-[480px] bg-gradient-to-b from-amber-50 to-orange-100 overflow-hidden select-none touch-none"
  onpointermove={handlePointerMove}
  onpointerup={handlePointerUp}
  bind:this={containerEl}
  role="application"
  aria-label="拖苹果凑十法游戏"
>
  <!-- Pet hint banner -->
  <div class="absolute top-4 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-amber-800 bg-white/70 rounded-full px-6 py-2 shadow-sm">
      🐱「帮我凑 {needed} 个苹果到碗里！」
    </p>
    <p class="text-sm text-amber-600 mt-1">碗里：{bowlCount}/{needed}</p>
  </div>

  <!-- Draggable apples (not in bowl) -->
  {#each apples.filter(a => !a.inBowl) as apple (apple.id)}
    <div
      class="absolute w-12 h-12 flex items-center justify-center text-3xl cursor-grab active:cursor-grabbing
        {dragging === apple.id ? 'scale-125 z-20' : 'hover:scale-110'} transition-transform"
      style="left: {apple.x}%; top: {apple.y}%;"
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
    class="absolute bottom-8 left-1/2 -translate-x-1/2 w-40 h-28 flex flex-col items-center justify-end
      border-4 border-dashed rounded-b-[80px] transition-all duration-300
      {bowlCount === needed ? 'border-green-400 bg-green-100/30' : ''}
      {bowlCount > 0 && bowlCount < needed ? 'border-amber-400 bg-amber-50/30' : ''}
      {bowlCount === 0 ? 'border-gray-300' : ''}"
  >
    <!-- Empty slot placeholders -->
    {#each bowlSlots as slot, i}
      {#if bowlOccupants[i] === -1}
        <div
          class="absolute w-6 h-6 rounded-full border border-dashed border-gray-300/40"
          style="left: {slot.x - 12}px; top: {slot.y - 12}px;"
        ></div>
      {/if}
    {/each}

    <!-- Apples already in bowl -->
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
    <span class="text-xs text-gray-500 mb-1">拖苹果到这里</span>
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
