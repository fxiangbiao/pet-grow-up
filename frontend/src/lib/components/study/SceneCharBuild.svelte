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

  // ── Valid combinations (部首 + 声旁 = 汉字) ──
  const VALID_COMBOS: Record<string, Record<string, string>> = {
    '亻': { '门': '们', '尔': '你', '十': '什', '也': '他', '半': '伴' },
    '氵': { '可': '河', '工': '江', '每': '海', '青': '清', '气': '汽', '先': '洗' },
    '口': { '十': '叶', '昌': '唱', '及': '吸', '马': '吗', '那': '哪', '牙': '呀' },
    '木': { '几': '机', '对': '树', '子': '李', '羊': '样', '交': '校' },
    '扌': { '丁': '打', '巴': '把', '合': '拾', '是': '提', '少': '抄' },
    '女': { '马': '妈', '且': '姐', '未': '妹', '生': '姓', '子': '好' },
    '日': { '免': '晚', '寸': '时', '目': '晴', '月': '明', '生': '星' },
    '月': { '半': '胖', '巴': '肥', '土': '肚', '要': '腰' },
    '讠': { '十': '计', '舌': '话', '上': '让', '人': '认', '只': '识' },
    '土': { '也': '地', '成': '城', '不': '坏', '云': '坛' },
  };

  // All available radicals and phonetics
  const ALL_RADICALS = Object.keys(VALID_COMBOS);
  const ALL_PHONETICS = [...new Set(Object.values(VALID_COMBOS).flatMap(v => Object.keys(v)))];

  // Parse target from question options
  function parseTarget(): { radical: string; phonetic: string; character: string } | null {
    const opts = question.options;
    let parsed: any = null;
    if (typeof opts === 'string') {
      try { parsed = JSON.parse(opts); } catch { /* fall through */ }
    } else if (typeof opts === 'object') {
      parsed = opts;
    }
    if (parsed?.targetChar) {
      // Find the combo that produces targetChar
      for (const [rad, phonMap] of Object.entries(VALID_COMBOS)) {
        for (const [phon, char] of Object.entries(phonMap)) {
          if (char === parsed.targetChar) {
            return { radical: rad, phonetic: phon, character: char };
          }
        }
      }
    }
    // Pick a random combo as fallback
    const radKeys = Object.keys(VALID_COMBOS);
    const rad = radKeys[Math.floor(Math.random() * radKeys.length)];
    const phonKeys = Object.keys(VALID_COMBOS[rad]);
    const phon = phonKeys[Math.floor(Math.random() * phonKeys.length)];
    return { radical: rad, phonetic: phon, character: VALID_COMBOS[rad][phon] };
  }

  const target = $derived(parseTarget());

  // ── Generate distractors ──
  function generateItems(): { radicals: string[]; phonetics: string[] } {
    if (!target) return { radicals: [], phonetics: [] };

    // Pick 3-4 radicals (including the correct one)
    const otherRads = ALL_RADICALS.filter(r => r !== target.radical).sort(() => Math.random() - 0.5);
    const radicals = [target.radical, ...otherRads.slice(0, 3)].sort(() => Math.random() - 0.5);

    // Pick 3-4 phonetics (including the correct one)
    const otherPhons = ALL_PHONETICS.filter(p => p !== target.phonetic).sort(() => Math.random() - 0.5);
    const phonetics = [target.phonetic, ...otherPhons.slice(0, 3)].sort(() => Math.random() - 0.5);

    return { radicals, phonetics };
  }

  const { radicals, phonetics } = $derived(generateItems());

  // ── State ──
  let leftSlot = $state<string | null>(null);   // radical slot
  let rightSlot = $state<string | null>(null);  // phonetic slot
  let combinedChar = $state<string | null>(null);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);
  let showResult = $state(false);
  let showGlow = $state(false);
  let availableRads = $state<string[]>([]);
  let availablePhons = $state<string[]>([]);

  $effect(() => {
    availableRads = [...radicals];
    availablePhons = [...phonetics];
  });

  // ── Actions ──
  function selectRadical(r: string) {
    if (submitted || showResult) return;
    // If already in slot, return it
    if (leftSlot === r) {
      availableRads = [...availableRads, r];
      leftSlot = null;
      combinedChar = null;
      return;
    }
    // Return previous left slot radical
    if (leftSlot) {
      availableRads = [...availableRads, leftSlot];
    }
    availableRads = availableRads.filter(ar => ar !== r);
    leftSlot = r;
    soundManager.playClick();
    tryCombine(r, rightSlot);
  }

  function selectPhonetic(p: string) {
    if (submitted || showResult) return;
    if (rightSlot === p) {
      availablePhons = [...availablePhons, p];
      rightSlot = null;
      combinedChar = null;
      return;
    }
    if (rightSlot) {
      availablePhons = [...availablePhons, rightSlot];
    }
    availablePhons = availablePhons.filter(ap => ap !== p);
    rightSlot = p;
    soundManager.playClick();
    tryCombine(leftSlot, p);
  }

  function tryCombine(rad: string | null, phon: string | null) {
    if (!rad || !phon) {
      combinedChar = null;
      showGlow = false;
      return;
    }
    const char = VALID_COMBOS[rad]?.[phon];
    if (char) {
      combinedChar = char;
      soundManager.playCharGlow();
      showGlow = true;
      // Auto-check if matches target
      if (rad === target?.radical && phon === target?.phonetic) {
        handleCorrect();
      }
    } else {
      combinedChar = null;
      showGlow = false;
      soundManager.playWrong();
    }
  }

  async function handleCorrect() {
    if (preview) return;
    submitted = true;
    showResult = true;
    showGlow = true;

    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: target?.character || '',
        timeSpent: 0
      });
      if (result) {
        feedback = 'correct';
        showFeedback = true;
        soundManager.playCorrect();
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('[CharBuild] onComplete failed:', e); }
        }, 2000);
      }
    } catch (err) {
      console.error('[CharBuild] Submit failed:', err);
      submitted = false;
      showResult = false;
      showGlow = false;
    }
  }

  function resetSlots() {
    if (submitted) return;
    if (leftSlot) availableRads = [...availableRads, leftSlot];
    if (rightSlot) availablePhons = [...availablePhons, rightSlot];
    leftSlot = null;
    rightSlot = null;
    combinedChar = null;
    showGlow = false;
  }
</script>

<div
  class="relative w-full min-h-[440px] bg-gradient-to-b from-stone-50 via-amber-50 to-yellow-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="汉字工坊"
>
  <!-- Decorative calligraphy strokes -->
  <div class="absolute top-2 right-3 text-6xl opacity-5 font-serif pointer-events-none">永</div>

  <!-- Hint -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-amber-900 bg-white/85 rounded-full px-5 py-1.5 shadow-sm border border-amber-200">
      🐱「{question.questionText || '选择偏旁和部首，拼出正确的汉字！'}」
    </p>
  </div>

  <div class="absolute inset-x-0 top-20 bottom-4 px-3 flex gap-3">
    <!-- Left: Radicals -->
    <div class="w-[30%] flex flex-col items-center gap-2">
      <p class="text-xs font-bold text-amber-700 mb-1">偏旁</p>
      {#each availableRads as rad (rad)}
        <button
          onclick={() => selectRadical(rad)}
          disabled={submitted}
          class={[
            'w-16 h-16 rounded-xl border-2 flex items-center justify-center text-2xl font-black',
            'transition-all duration-200 shadow-sm',
            !submitted ? 'cursor-pointer hover:scale-110 active:scale-95' : '',
            leftSlot === rad
              ? 'border-indigo-500 bg-indigo-100 ring-2 ring-indigo-300 scale-105'
              : 'bg-white border-amber-300 hover:border-indigo-400 hover:bg-indigo-50',
          ].join(' ')}
          aria-label={'偏旁 ' + rad}
        >
          {rad}
        </button>
      {/each}
    </div>

    <!-- Center: Synthesis table -->
    <div class="flex-1 flex flex-col items-center justify-center gap-4">
      <!-- Target hint -->
      <p class="text-xs text-amber-600 font-medium">合成台</p>

      <div class="flex items-center gap-3">
        <!-- Left slot -->
        <div class={[
          'w-20 h-20 rounded-2xl border-3 border-dashed flex items-center justify-center transition-all duration-300',
          leftSlot ? 'border-indigo-400 bg-indigo-50' : 'border-amber-300 bg-white/60',
        ].join(' ')}>
          {#if leftSlot}
            <span class="text-3xl font-black text-indigo-700">{leftSlot}</span>
          {:else}
            <span class="text-gray-300 text-3xl">?</span>
          {/if}
        </div>

        <!-- Plus sign -->
        <span class="text-2xl text-amber-400 font-bold">+</span>

        <!-- Right slot -->
        <div class={[
          'w-20 h-20 rounded-2xl border-3 border-dashed flex items-center justify-center transition-all duration-300',
          rightSlot ? 'border-indigo-400 bg-indigo-50' : 'border-amber-300 bg-white/60',
        ].join(' ')}>
          {#if rightSlot}
            <span class="text-3xl font-black text-indigo-700">{rightSlot}</span>
          {:else}
            <span class="text-gray-300 text-3xl">?</span>
          {/if}
        </div>

        <!-- Equals -->
        <span class="text-2xl text-amber-400 font-bold">=</span>

        <!-- Result -->
        <div class={[
          'w-20 h-20 rounded-2xl border-3 flex items-center justify-center transition-all duration-500',
          showGlow && combinedChar
            ? 'border-green-400 bg-green-50 shadow-lg shadow-green-200'
            : 'border-gray-200 bg-white/60',
        ].join(' ')}>
          {#if combinedChar}
            <span class={[
              'text-4xl font-black transition-all duration-500',
              showGlow ? 'text-green-600 scale-110 animate-bounce-in' : 'text-gray-500',
            ].join(' ')}>
              {combinedChar}
            </span>
          {:else}
            <span class="text-gray-300 text-3xl">?</span>
          {/if}
        </div>
      </div>

      {#if !submitted}
        <button onclick={resetSlots}
          class="px-4 py-1.5 text-xs text-gray-500 bg-white/70 rounded-full border border-gray-200 hover:bg-gray-100 transition">
          🔄 清空重试
        </button>
      {/if}
    </div>

    <!-- Right: Phonetics -->
    <div class="w-[30%] flex flex-col items-center gap-2">
      <p class="text-xs font-bold text-amber-700 mb-1">声旁</p>
      {#each availablePhons as phon (phon)}
        <button
          onclick={() => selectPhonetic(phon)}
          disabled={submitted}
          class={[
            'w-16 h-16 rounded-xl border-2 flex items-center justify-center text-2xl font-black',
            'transition-all duration-200 shadow-sm',
            !submitted ? 'cursor-pointer hover:scale-110 active:scale-95' : '',
            rightSlot === phon
              ? 'border-indigo-500 bg-indigo-100 ring-2 ring-indigo-300 scale-105'
              : 'bg-white border-amber-300 hover:border-indigo-400 hover:bg-indigo-50',
          ].join(' ')}
          aria-label={'声旁 ' + phon}
        >
          {phon}
        </button>
      {/each}
    </div>
  </div>

  <!-- Success overlay -->
  {#if showResult && feedback === 'correct'}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in text-center">
        ✨ 造字成功！<br />
        <span class="text-5xl font-black block mt-1">{combinedChar}</span>
        <span class="text-sm font-normal">{leftSlot} + {rightSlot} = {combinedChar}</span>
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
