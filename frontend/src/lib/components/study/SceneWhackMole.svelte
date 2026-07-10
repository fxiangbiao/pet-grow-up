<script lang="ts">
  import { submitAnswer, type QuestionDTO, type AnswerResult } from '$lib/api/study';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    question,
    sessionId,
    onComplete,
    preview = false
  }: {
    question: QuestionDTO;
    sessionId: number;
    onComplete: (result: AnswerResult) => void;
    preview?: boolean;
  } = $props();

  // ── Parse numeric options ──
  function parseNumberOptions(raw: string | null | Array<{ key: string; text: string }>): Array<{ key: string; text: string }> {
    if (!raw) return [];
    if (Array.isArray(raw)) return raw as Array<{ key: string; text: string }>;
    if (typeof raw === 'string') {
      try {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed as Array<{ key: string; text: string }>;
      } catch { /* fall through */ }
    }
    if (typeof raw === 'object' && raw !== null) {
      try { return Object.entries(raw).map(([k, v]) => ({ key: k, text: String(v) })); } catch { /* empty */ }
    }
    return [];
  }

  const options = parseNumberOptions(question.options as string | null);

  // ── Mole hole positions (3×3 grid) ──
  interface MoleState {
    index: number;
    optionKey: string;
    optionText: string;
    visible: boolean;
    whacked: boolean;
  }

  const HOLES = 9;
  let moles = $state<Map<number, MoleState>>(new Map());
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);
  let timeLeft = $state(8);
  let timerActive = $state(false);

  let moleTimer: ReturnType<typeof setInterval> | null = null;
  let countdownTimer: ReturnType<typeof setInterval> | null = null;

  // ── Spawn moles: populate random holes with options ──
  function spawnMoles() {
    const newMoles = new Map<number, MoleState>();
    if (options.length === 0) return newMoles;

    // Pick 4-6 random holes
    const count = Math.min(options.length, 4 + Math.floor(Math.random() * 3));
    const shuffledHoles = [...Array(HOLES).keys()].sort(() => Math.random() - 0.5).slice(0, count);
    // Shuffle options among holes
    const shuffledOpts = [...options].sort(() => Math.random() - 0.5);

    shuffledHoles.forEach((holeIdx, i) => {
      newMoles.set(holeIdx, {
        index: holeIdx,
        optionKey: shuffledOpts[i].key,
        optionText: shuffledOpts[i].text,
        visible: true,
        whacked: false,
      });
    });
    return newMoles;
  }

  // ── Refresh moles periodically ──
  function startMoleCycle() {
    moles = spawnMoles();
    soundManager.playMoleAppear();

    moleTimer = setInterval(() => {
      if (submitted) {
        if (moleTimer) clearInterval(moleTimer);
        return;
      }
      // Hide all, then respawn after brief delay
      moles.forEach(m => { m.visible = false; });
      setTimeout(() => {
        if (!submitted) {
          moles = spawnMoles();
          soundManager.playMoleAppear();
        }
      }, 400);
    }, 1800);
  }

  function startCountdown() {
    timerActive = true;
    countdownTimer = setInterval(() => {
      timeLeft--;
      if (timeLeft <= 0) {
        // Time's up — auto-submit with a random wrong answer or empty
        if (!submitted) {
          handleTap('__timeout__');
        }
      }
    }, 1000);
  }

  // ── Cleanup on unmount ──
  function cleanup() {
    if (moleTimer) clearInterval(moleTimer);
    if (countdownTimer) clearInterval(countdownTimer);
  }

  // Start on mount (skip in preview mode)
  $effect(() => {
    if (preview) return;
    startMoleCycle();
    startCountdown();
    return cleanup;
  });

  async function handleTap(optionKey: string) {
    if (submitted) return;
    if (preview) return;
    submitted = true;
    timerActive = false;
    cleanup();

    if (optionKey === '__timeout__') {
      soundManager.playWrong();
      try {
        const result = await submitAnswer({
          sessionId,
          questionId: question.questionId,
          answer: '',
          timeSpent: 8
        });
        if (result) {
          feedback = 'wrong';
          showFeedback = true;
          setTimeout(() => { try { onComplete(result); } catch (e) { console.error('[WhackMole] onComplete failed:', e); } }, 1200);
        }
      } catch (err) {
        console.error('[WhackMole] Timeout submit failed:', err);
        submitted = false; timerActive = true; startCountdown(); startMoleCycle();
      }
      return;
    }

    soundManager.playMoleWhack();

    // Mark all moles as whacked for visual
    moles.forEach(m => { m.whacked = true; });

    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: optionKey,
        timeSpent: Math.max(0, 8 - timeLeft)
      });
      if (result) {
        feedback = result.isCorrect ? 'correct' : 'wrong';
        showFeedback = true;
        if (result.isCorrect) {
          soundManager.playCorrect();
        } else {
          soundManager.playWrong();
        }
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('[WhackMole] onComplete failed:', e); }
        }, 1200);
      } else {
        throw new Error('Empty API result');
      }
    } catch (err) {
      console.error('[WhackMole] Submit failed:', err);
      submitted = false;
      timerActive = true;
      startCountdown();
      startMoleCycle();
      // Reset whacked state
      moles.forEach(m => { m.whacked = false; });
    }
  }

  // ── Mole display helpers ──
  function getMoleRowCol(idx: number): { row: number; col: number } {
    return { row: Math.floor(idx / 3), col: idx % 3 };
  }
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-green-100 via-lime-50 to-amber-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="打地鼠答题"
>
  <!-- Grass/ground decoration -->
  <div class="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-green-700/30 to-transparent pointer-events-none"></div>

  <!-- Pet hint + question + timer -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10 flex items-center gap-3">
    <p class="text-lg font-bold text-amber-800 bg-white/85 rounded-full px-5 py-1.5 shadow-sm">
      🐱「{question.questionText || '敲正确答案！'}」
    </p>
    <span class="text-sm font-bold px-3 py-1 rounded-full transition-colors"
      class:bg-red-500={timeLeft <= 3}
      class:bg-amber-400={timeLeft > 3}
      class:text-white={true}>
      ⏱ {timeLeft}s
    </span>
  </div>

  <!-- 3×3 Mole grid -->
  <div class="absolute inset-x-0 top-16 bottom-16 flex items-center justify-center">
    <div class="grid grid-cols-3 gap-4 p-4" style="width: 320px;">
      {#each Array(HOLES) as _, idx}
        {@const mole = moles.get(idx)}
        {@const { row, col } = getMoleRowCol(idx)}
        <div class="relative flex items-center justify-center" style="width: 90px; height: 90px;">
          <!-- Hole -->
          <div class="absolute bottom-1 w-20 h-10 bg-amber-900/40 rounded-[50%] blur-[2px]"></div>

          <!-- Mole (if present) -->
          {#if mole && mole.visible}
            <button
              onclick={() => handleTap(mole.optionKey)}
              disabled={submitted}
              class={[
                'absolute bottom-3 w-20 h-20 rounded-full flex flex-col items-center justify-center',
                'transition-all duration-200 shadow-lg border-3',
                !submitted ? 'cursor-pointer hover:scale-110 active:scale-95' : '',
                mole.whacked && feedback === 'correct'
                  ? 'bg-green-400 border-green-600 scale-90'
                  : mole.whacked && feedback === 'wrong' && submitted
                    ? 'bg-red-400 border-red-600 scale-90'
                    : 'bg-amber-300 border-amber-600 hover:bg-amber-200',
              ].join(' ')}
              style="animation: moleUp 0.25s ease-out;"
              aria-label={'答案 ' + mole.optionText}
            >
              <!-- Mole face -->
              <span class="text-2xl leading-none">🐹</span>
              <span class="text-sm font-black text-amber-900">{mole.optionText}</span>
            </button>
          {:else}
            <!-- Empty hole bump -->
            <div class="absolute bottom-2 w-16 h-10 bg-amber-800/20 rounded-[50%]"></div>
          {/if}
        </div>
      {/each}
    </div>
  </div>

  <!-- Feedback overlay -->
  {#if showFeedback}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      {#if feedback === 'correct'}
        <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in">
          ✅ 砸中啦！
        </div>
      {:else if feedback === 'wrong'}
        <div class="bg-red-400 text-white text-xl font-bold px-6 py-3 rounded-2xl shadow-xl animate-shake">
          {timeLeft <= 0 ? '⏰ 时间到！' : '❌ 砸错了～'}
        </div>
      {/if}
    </div>
  {/if}
</div>

<style lang="postcss">
  @keyframes moleUp {
    0% { transform: translateY(40px); opacity: 0; }
    100% { transform: translateY(0); opacity: 1; }
  }
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
