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

  // ── Shape definitions ──
  interface ShapeOption {
    key: string;
    label: string;
    cssShape: 'circle' | 'square' | 'triangle' | 'rectangle';
    color: 'sky' | 'amber' | 'rose' | 'emerald' | 'violet' | 'teal' | 'orange' | 'pink';
  }

  const DEFAULT_SHAPES: ShapeOption[] = [
    { key: 'CIRCLE', label: '圆形', cssShape: 'circle', color: 'sky' },
    { key: 'SQUARE', label: '正方形', cssShape: 'square', color: 'amber' },
    { key: 'TRIANGLE', label: '三角形', cssShape: 'triangle', color: 'rose' },
    { key: 'RECTANGLE', label: '长方形', cssShape: 'rectangle', color: 'emerald' },
  ];

  // Predefined Tailwind classes per color (JIT-safe, all strings statically analyzable)
  const SHAPE_FILL: Record<ShapeOption['color'], string> = {
    sky:     'bg-sky-400 border-sky-600',
    amber:   'bg-amber-400 border-amber-600',
    rose:    'bg-rose-400 border-rose-600',
    emerald: 'bg-emerald-400 border-emerald-600',
    violet:  'bg-violet-400 border-violet-600',
    teal:    'bg-teal-400 border-teal-600',
    orange:  'bg-orange-400 border-orange-600',
    pink:    'bg-pink-400 border-pink-600',
  };
  const TRIANGLE_COLOR: Record<ShapeOption['color'], string> = {
    sky:     '#38bdf8',
    amber:   '#fbbf24',
    rose:    '#fb7185',
    emerald: '#34d399',
    violet:  '#a78bfa',
    teal:    '#2dd4bf',
    orange:  '#fb923c',
    pink:    '#f472b6',
  };

  function parseShapeOptions(raw: string | null): ShapeOption[] {
    if (!raw) return DEFAULT_SHAPES;
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed as ShapeOption[];
    } catch { /* fall through */ }
    // Also handle pre-deserialized array
    if (Array.isArray(raw)) return raw as unknown as ShapeOption[];
    return DEFAULT_SHAPES;
  }

  let shapeOptions = $state<ShapeOption[]>(DEFAULT_SHAPES);

  // Parse on init
  shapeOptions = parseShapeOptions(question.options as string | null);

  // ── State ──
  let selected = $state<string | null>(null);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);

  async function handleSelect(key: string) {
    if (submitted) return;
    if (preview) return;
    selected = key;
    submitted = true;
    soundManager.playClick();

    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: key,
        timeSpent: 0
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
          try { onComplete(result); } catch (e) { console.error('[SceneMatch] onComplete failed:', e); }
        }, 1200);
      } else {
        throw new Error('Empty API result');
      }
    } catch (err) {
      console.error('[SceneMatch] Submit failed:', err);
      submitted = false;
      selected = null;
      feedback = 'idle';
      showFeedback = false;
    }
  }
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-violet-50 to-purple-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="点击选择图形"
>
  <!-- Pet hint banner -->
  <div class="absolute top-4 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-purple-800 bg-white/80 rounded-full px-6 py-2 shadow-sm">
      🐱「{question.questionText || '点击正确的图形吧！'}」
    </p>
  </div>

  <!-- Shape cards grid -->
  <div class="absolute inset-x-0 top-24 bottom-8 flex flex-wrap items-center justify-center gap-5 px-4 content-center">
    {#each shapeOptions as shape}
      <button
        onclick={() => handleSelect(shape.key)}
        disabled={submitted}
        class={[
          'w-32 h-36 rounded-2xl border-4 flex flex-col items-center justify-center gap-3 transition-all duration-200',
          'hover:scale-105 active:scale-95 shadow-lg',
          !submitted ? 'cursor-pointer bg-white border-gray-200 hover:border-purple-400' : '',
          submitted && selected === shape.key
            ? (feedback === 'correct' ? 'border-green-500 bg-green-50 scale-105' : 'border-red-500 bg-red-50 scale-95')
            : '',
          submitted && selected !== shape.key ? 'opacity-40 scale-90' : ''
        ].join(' ')}
        aria-label={shape.label}
      >
        <!-- CSS-drawn shape -->
        <span class="inline-flex items-center justify-center w-14 h-14">
          {#if shape.cssShape === 'circle'}
            <span class="block w-12 h-12 rounded-full border-2 shadow-inner {SHAPE_FILL[shape.color]}"></span>
          {:else if shape.cssShape === 'square'}
            <span class="block w-12 h-12 rounded-md border-2 shadow-inner {SHAPE_FILL[shape.color]}"></span>
          {:else if shape.cssShape === 'triangle'}
            <span class="block w-0 h-0 border-solid"
              style="border-left: 28px solid transparent; border-right: 28px solid transparent; border-bottom: 48px solid {TRIANGLE_COLOR[shape.color]}; filter: drop-shadow(0 2px 2px rgb(0 0 0 / 0.15));"
            ></span>
          {:else if shape.cssShape === 'rectangle'}
            <span class="block rounded-md border-2 shadow-inner {SHAPE_FILL[shape.color]}"
              style="width: 56px; height: 32px;"
            ></span>
          {/if}
        </span>
        <span class="text-sm font-semibold text-gray-700">{shape.label}</span>
      </button>
    {/each}
  </div>

  <!-- Feedback overlay -->
  {#if showFeedback}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      {#if feedback === 'correct'}
        <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in">
          ✅ 答对啦！
        </div>
      {:else if feedback === 'wrong'}
        <div class="bg-red-400 text-white text-xl font-bold px-6 py-3 rounded-2xl shadow-xl animate-shake">
          ❌ 再想想～
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
