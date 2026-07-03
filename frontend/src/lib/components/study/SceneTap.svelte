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

  // ── Parse options (multi-format, supports optional `color` field) ──
  interface ParsedOption {
    key: string;
    text: string;
    color?: string; // optional: semantic color name like 'green', 'red'
  }

  function parseOptions(raw: string | null | Array<any>): ParsedOption[] {
    if (!raw) return [];
    if (Array.isArray(raw)) return raw.map((o: any) => ({
      key: o.key || '',
      text: o.text || String(o),
      color: o.color || undefined,
    }));
    if (typeof raw === 'string') {
      try {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed.map((o: any) => ({
          key: o.key || '',
          text: o.text || String(o),
          color: o.color || undefined,
        }));
      } catch { /* fall through */ }
    }
    if (typeof raw === 'object' && raw !== null) {
      try {
        return Object.entries(raw).map(([k, v]) => ({ key: k, text: String(v) }));
      } catch { /* empty */ }
    }
    return [];
  }

  const options = parseOptions(question.options as string | null);

  // ── State ──
  let selected = $state<string | null>(null);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);

  // Default bubble colors — cheerful palette (used when option has no explicit color)
  const defaultBubbleColors = [
    { bg: 'bg-sky-100', border: 'border-sky-400', text: 'text-sky-800' },
    { bg: 'bg-pink-100', border: 'border-pink-400', text: 'text-pink-800' },
    { bg: 'bg-emerald-100', border: 'border-emerald-400', text: 'text-emerald-800' },
    { bg: 'bg-amber-100', border: 'border-amber-400', text: 'text-amber-800' },
    { bg: 'bg-violet-100', border: 'border-violet-400', text: 'text-violet-800' },
    { bg: 'bg-rose-100', border: 'border-rose-400', text: 'text-rose-800' },
  ];

  // Semantic color mapping — when option.color is specified
  const semanticColors: Record<string, { bg: string; border: string; text: string }> = {
    red:    { bg: 'bg-red-100', border: 'border-red-400', text: 'text-red-800' },
    orange: { bg: 'bg-orange-100', border: 'border-orange-400', text: 'text-orange-800' },
    yellow: { bg: 'bg-yellow-100', border: 'border-yellow-400', text: 'text-yellow-800' },
    green:  { bg: 'bg-green-100', border: 'border-green-400', text: 'text-green-800' },
    blue:   { bg: 'bg-blue-100', border: 'border-blue-400', text: 'text-blue-800' },
    purple: { bg: 'bg-purple-100', border: 'border-purple-400', text: 'text-purple-800' },
    pink:   { bg: 'bg-pink-100', border: 'border-pink-400', text: 'text-pink-800' },
    white:  { bg: 'bg-white', border: 'border-gray-400', text: 'text-gray-800' },
    black:  { bg: 'bg-gray-200', border: 'border-gray-600', text: 'text-gray-900' },
    brown:  { bg: 'bg-amber-100', border: 'border-amber-600', text: 'text-amber-900' },
  };

  function getBubbleColor(opt: ParsedOption, idx: number): { bg: string; border: string; text: string } {
    if (opt.color && semanticColors[opt.color]) {
      return semanticColors[opt.color];
    }
    return defaultBubbleColors[idx % defaultBubbleColors.length];
  }

  async function handleTap(key: string) {
    if (submitted) return;
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
          try { onComplete(result); } catch (e) { console.error('[SceneTap] onComplete failed:', e); }
        }, 1200);
      } else {
        throw new Error('Empty API result');
      }
    } catch (err) {
      console.error('[SceneTap] Submit failed:', err);
      submitted = false;
      selected = null;
      feedback = 'idle';
      showFeedback = false;
    }
  }
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-sky-50 to-indigo-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="点击选择答案"
>
  <!-- Pet hint banner -->
  <div class="absolute top-4 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-indigo-800 bg-white/80 rounded-full px-6 py-2 shadow-sm">
      🐱「{question.questionText || '点击正确答案吧！'}」
    </p>
  </div>

  <!-- Option bubbles -->
  <div class="absolute inset-x-0 top-24 bottom-8 flex flex-wrap items-center justify-center gap-4 px-6 content-center">
    {#each options as opt, i}
      {@const color = getBubbleColor(opt, i)}
      <button
        onclick={() => handleTap(opt.key)}
        disabled={submitted}
        class={[
          'w-28 h-28 rounded-full border-4 flex flex-col items-center justify-center gap-1 transition-all duration-200',
          'hover:scale-110 active:scale-95 shadow-lg',
          !submitted ? 'cursor-pointer hover:shadow-xl ' + color.bg + ' ' + color.border + ' ' + color.text : '',
          submitted && selected === opt.key
            ? (feedback === 'correct' ? 'bg-green-100 border-green-500 scale-110' : 'bg-red-100 border-red-500 scale-95')
            : '',
          submitted && selected !== opt.key ? 'opacity-40 scale-90' : ''
        ].join(' ')}
        aria-label={'选项 ' + opt.key + ': ' + opt.text}
      >
        <span class="text-lg font-black opacity-40">{opt.key}</span>
        <span class="text-xl font-bold">{opt.text}</span>
      </button>
    {/each}

    {#if options.length === 0}
      <p class="text-gray-400 text-sm">⚠️ 选项加载异常</p>
    {/if}
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
