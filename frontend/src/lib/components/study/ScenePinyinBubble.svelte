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

  // ── Parse options ──
  function parseOptions(raw: string | null | Array<{ key: string; text: string }>): Array<{ key: string; text: string }> {
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

  const options = parseOptions(question.options as string | null);

  // ── Bubble positions with random drift ──
  interface BubbleState {
    opt: { key: string; text: string };
    x: number;
    y: number;
    delay: number;
    driftX: number;
    driftY: number;
    popped: boolean;
    color: { bg: string; border: string; text: string };
  }

  const BUBBLE_COLORS = [
    { bg: 'bg-sky-300/80', border: 'border-sky-500', text: 'text-sky-900' },
    { bg: 'bg-pink-300/80', border: 'border-pink-500', text: 'text-pink-900' },
    { bg: 'bg-emerald-300/80', border: 'border-emerald-500', text: 'text-emerald-900' },
    { bg: 'bg-amber-300/80', border: 'border-amber-500', text: 'text-amber-900' },
    { bg: 'bg-violet-300/80', border: 'border-violet-500', text: 'text-violet-900' },
    { bg: 'bg-rose-300/80', border: 'border-rose-500', text: 'text-rose-900' },
    { bg: 'bg-teal-300/80', border: 'border-teal-500', text: 'text-teal-900' },
    { bg: 'bg-orange-300/80', border: 'border-orange-500', text: 'text-orange-900' },
  ];

  function generateBubbles(): BubbleState[] {
    if (options.length === 0) return [];
    // Position in a scattered grid within the container
    return options.map((opt, i) => {
      const cols = Math.ceil(Math.sqrt(options.length));
      const row = Math.floor(i / cols);
      const col = i % cols;
      const baseX = 15 + (70 / (cols - 1 || 1)) * col;
      const baseY = 20 + (60 / (Math.ceil(options.length / cols) - 1 || 1)) * row;
      return {
        opt,
        x: baseX + (Math.random() - 0.5) * 12,
        y: baseY + (Math.random() - 0.5) * 12,
        delay: Math.random() * 2,
        driftX: (Math.random() - 0.5) * 30,
        driftY: (Math.random() - 0.5) * 20,
        popped: false,
        color: BUBBLE_COLORS[i % BUBBLE_COLORS.length],
      };
    });
  }

  let bubbles = $state<BubbleState[]>([]);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);
  let speaking = $state(false);

  $effect(() => {
    bubbles = generateBubbles();
  });

  // ── Speech synthesis ──
  function speakPinyin() {
    if (speaking || submitted) return;
    speaking = true;
    try {
      const utterance = new SpeechSynthesisUtterance(question.questionText || '');
      utterance.lang = 'zh-CN';
      utterance.rate = 0.7;
      utterance.onend = () => { speaking = false; };
      utterance.onerror = () => { speaking = false; };
      speechSynthesis.speak(utterance);
    } catch {
      speaking = false;
    }
  }

  // Auto-speak on mount (skip in preview mode)
  $effect(() => {
    if (preview) return;
    const t = setTimeout(() => { speakPinyin(); }, 300);
    return () => clearTimeout(t);
  });

  async function handleTap(key: string) {
    if (submitted) return;
    if (preview) return;

    // Find and pop the bubble
    const bubble = bubbles.find(b => b.opt.key === key);
    if (!bubble) return;
    bubble.popped = true;
    soundManager.playBubblePop();

    submitted = true;

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
          try { onComplete(result); } catch (e) { console.error('[PinyinBubble] onComplete failed:', e); }
        }, 1200);
      }
    } catch (err) {
      console.error('[PinyinBubble] Submit failed:', err);
      submitted = false;
      bubble.popped = false;
    }
  }

  // Re-speak button handler
  function replay() {
    if (submitted) return;
    speechSynthesis.cancel();
    speaking = false;
    setTimeout(() => speakPinyin(), 100);
  }
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-cyan-100 via-blue-50 to-indigo-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="拼音泡泡"
>
  <!-- Hint -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10 flex items-center gap-2">
    <p class="text-lg font-bold text-indigo-800 bg-white/80 rounded-full px-5 py-1.5 shadow-sm">
      🐱「{question.questionText || '听发音，点击正确的拼音！'}」
    </p>
    <button onclick={replay} disabled={submitted || speaking}
      class="w-10 h-10 rounded-full bg-indigo-500 text-white flex items-center justify-center shadow-md
        hover:bg-indigo-600 disabled:opacity-50 transition text-xl"
      aria-label="重播发音">
      {speaking ? '🔊' : '🔈'}
    </button>
  </div>

  <!-- Bubble field -->
  <div class="absolute inset-0 top-20 bottom-8">
    {#each bubbles as bubble (bubble.opt.key)}
      {#if !bubble.popped}
        <button
          onclick={() => handleTap(bubble.opt.key)}
          disabled={submitted}
          class={[
            'absolute w-20 h-20 rounded-full border-4 flex items-center justify-center',
            'transition-all duration-300 shadow-lg',
            !submitted ? 'cursor-pointer hover:scale-110 active:scale-95 ' + bubble.color.bg + ' ' + bubble.color.border + ' ' + bubble.color.text : '',
            'animate-float-bubble',
          ].join(' ')}
          style="left: {bubble.x}%; top: {bubble.y}%; animation-delay: {bubble.delay}s;"
          aria-label={'拼音 ' + bubble.opt.text}
        >
          <!-- Bubble shine -->
          <span class="absolute top-2 left-3 w-3 h-3 rounded-full bg-white/60"></span>
          <span class="text-xl font-black">{bubble.opt.text}</span>
        </button>
      {:else}
        <!-- Popped: small water droplets -->
        <div
          class="absolute pointer-events-none"
          style="left: {bubble.x}%; top: {bubble.y}%;"
        >
          {#each Array(6) as _, i}
            <span
              class="absolute w-2 h-2 rounded-full bg-blue-300/70 animate-ping"
              style="
                animation-delay: {i * 0.05}s;
                left: {Math.cos(i * 60 * Math.PI / 180) * 15}px;
                top: {Math.sin(i * 60 * Math.PI / 180) * 15}px;
              "
            ></span>
          {/each}
        </div>
      {/if}
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
          ❌ 再听听～
        </div>
      {/if}
    </div>
  {/if}
</div>

<style lang="postcss">
  @keyframes floatBubble {
    0%, 100% { transform: translate(0, 0); }
    25% { transform: translate(8px, -10px); }
    50% { transform: translate(-4px, -16px); }
    75% { transform: translate(-8px, -6px); }
  }
  :global(.animate-float-bubble) {
    animation: floatBubble 4s ease-in-out infinite;
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
