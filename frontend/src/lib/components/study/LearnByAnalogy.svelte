<script lang="ts">
  import { generateVariant } from '$lib/api/study';
  // 复用探究页的专用输入组件：它们只吃 options/disabled/onSelect，不依赖题号与 sessionId，
  // 因此可以直接用在"变式题"上，且答案载荷与探究页完全一致（本地判分口径相同）。
  import MathInput from '$lib/components/study/MathInput.svelte';
  import PoemSequence from '$lib/components/study/PoemSequence.svelte';
  import VocabMatch from '$lib/components/study/VocabMatch.svelte';

  interface Props {
    nodeId: number;
    originalQuestionId: number;
    originalText: string;
    originalAnswer: string;
    subject: string;
    onComplete: (success: boolean, energyReward?: number) => void;
  }

  let { nodeId, originalQuestionId, originalText, originalAnswer, subject, onComplete }: Props = $props();

  interface VariantOption {
    key: string;
    text: string;
  }

  type Step = 'intro' | 'show_variant' | 'spirit_judge' | 'spirit_explain' | 'result' | 'failed';

  const OPTION_LABELS = ['A', 'B', 'C', 'D', 'E', 'F'];

  let step = $state<Step>('intro');
  let variant = $state<any>(null);
  let loading = $state(false);
  let error = $state('');

  // 孩子的作答
  let selectedOption = $state('');
  let fillAnswer = $state('');
  let childGraded = $state(false);
  let childCorrect = $state(false);

  // 小精灵的答案（spiritIsWrong = false 表示构造不出确实错误的答案，不判定对错）
  let spiritAnswer = $state('');
  let spiritIsWrong = $state(false);
  let spiritVerdict = $state<'' | 'right' | 'wrong'>('');

  // 孩子的讲解
  let childReason = $state('');

  // ── 答案判定 ──
  function normalize(value: unknown): string {
    return String(value ?? '').trim().replace(/\s+/g, '').toLowerCase();
  }

  function asNumber(value: unknown): number | null {
    const s = String(value ?? '').trim();
    if (!/^[+-]?\d+(\.\d+)?$/.test(s)) return null;
    const n = Number(s);
    return Number.isFinite(n) ? n : null;
  }

  /** 归一化判定：去首尾空白、大小写不敏感、纯数字按数值比较 */
  function isAnswerCorrect(child: unknown, correct: unknown): boolean {
    const c = normalize(child);
    const t = normalize(correct);
    if (!c || !t) return false;
    const cn = asNumber(c);
    const tn = asNumber(t);
    if (cn !== null && tn !== null) return cn === tn;
    return c === t;
  }

  function parseOptions(raw: any): VariantOption[] {
    if (!raw) return [];
    let list: any = raw;
    if (typeof raw === 'string') {
      try {
        list = JSON.parse(raw);
      } catch {
        return [];
      }
    }
    if (Array.isArray(list)) {
      return list
        .map((item: any, i: number) => {
          if (item && typeof item === 'object') {
            return {
              key: String(item.key ?? OPTION_LABELS[i] ?? i),
              text: String(item.text ?? item.label ?? '')
            };
          }
          return { key: OPTION_LABELS[i] ?? String(i), text: String(item ?? '') };
        })
        .filter((o: VariantOption) => o.text !== '');
    }
    if (typeof list === 'object' && list !== null) {
      return Object.entries(list).map(([k, v]) => ({ key: k, text: String(v) }));
    }
    return [];
  }

  let parsedOptions = $derived(parseOptions(variant?.options));

  // ── 题型适配 ──
  // ① 选项类：选择题与 SCENE_TAP 都以选项 key 交答案（探究页的练习环节同样把 SCENE_TAP 渲染成选项）
  // ② 专用组件类：复用探究页的 MathInput / PoemSequence / VocabMatch
  // ③ 场景组件类：SCENE_DRAG / SCENE_MATCH 等由各自组件按题号自行向后端提交答案，
  //    而变式题不在题库里、没有题号 → 无法复用；此时如实说明并给出出口，绝不误判孩子答错
  const COMPONENT_INPUT_TYPES = ['MATH_INPUT', 'POEM_SEQUENCE', 'VOCAB_MATCH'];
  const SCENE_ONLY_TYPES = [
    'SCENE_DRAG', 'SCENE_MATCH', 'SCENE_WHACK_MOLE', 'SCENE_SHAPE_PUZZLE',
    'SCENE_CLOCK', 'SCENE_SHOP', 'SCENE_PINYIN', 'SCENE_CHAR_BUILD'
  ];

  let variantType = $derived(String(variant?.questionType ?? ''));
  let isChoice = $derived(
    parsedOptions.length > 0 && (variantType === 'MULTIPLE_CHOICE' || variantType === 'SCENE_TAP')
  );
  let isTrueFalse = $derived(variantType === 'TRUE_FALSE');
  let useComponentInput = $derived(COMPONENT_INPUT_TYPES.includes(variantType));
  let isSceneOnly = $derived(SCENE_ONLY_TYPES.includes(variantType));

  // 专用组件回报的答案（诗句排序的索引串 / 单词配对串 / 数字）
  let componentAnswer = $state('');

  /** 诗句排序的选项是字符串数组 */
  function parsePoemLines(raw: any): string[] {
    try {
      const p = typeof raw === 'string' ? JSON.parse(raw) : raw;
      return Array.isArray(p) ? p.map((x: any) => String(x)) : [];
    } catch {
      return [];
    }
  }

  /** 单词配对的选项是 { left: [{id,text}], right: [{id,text}] } */
  function parseVocabOptions(raw: any): any {
    try {
      const p = typeof raw === 'string' ? JSON.parse(raw) : raw;
      if (p && typeof p === 'object' && !Array.isArray(p) && p.left && p.right) return p;
    } catch {
      /* ignore */
    }
    return null;
  }

  let poemLines = $derived(variantType === 'POEM_SEQUENCE' ? parsePoemLines(variant?.options) : []);
  let vocabOptions = $derived(
    variantType === 'VOCAB_MATCH' ? parseVocabOptions(variant?.options) : null
  );

  const correctRaw = $derived(String(variant?.correctAnswer ?? '').trim());

  /**
   * 按题型比对答案。
   * 单词配对交的是 "1a,2b" 这种配对串，孩子先点哪一对不该影响判定，
   * 所以分词排序后再比；诗句排序则必须保持顺序敏感（它就考顺序）。
   */
  function checkAnswer(child: unknown, correct: unknown, type: string): boolean {
    if (type === 'VOCAB_MATCH') {
      const canon = (v: unknown) =>
        String(v ?? '')
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .filter(Boolean)
          .sort()
          .join(',');
      const c = canon(child);
      return c !== '' && c === canon(correct);
    }
    return isAnswerCorrect(child, correct);
  }

  let correctOption = $derived.by(() => {
    if (!isChoice) return null;
    const byKey = parsedOptions.find((o) => normalize(o.key) === normalize(correctRaw));
    if (byKey) return byKey;
    return parsedOptions.find((o) => normalize(o.text) === normalize(correctRaw)) ?? null;
  });

  let correctDisplay = $derived(
    correctOption ? `${correctOption.key}. ${correctOption.text}` : correctRaw || '（未提供）'
  );

  let childRawValue = $derived(
    isChoice || isTrueFalse ? selectedOption : (componentAnswer || fillAnswer).trim()
  );

  let childAnswerDisplay = $derived.by(() => {
    if (isChoice) {
      const opt = parsedOptions.find((o) => o.key === selectedOption);
      return opt ? `${opt.key}. ${opt.text}` : selectedOption;
    }
    if (isTrueFalse) {
      return selectedOption === 'true' ? '✓ 正确' : selectedOption === 'false' ? '✗ 错误' : '';
    }
    return (componentAnswer || fillAnswer).trim();
  });

  let canConfirm = $derived(childRawValue.length > 0);

  let showOriginalAnswer = $derived(
    !!originalAnswer && originalAnswer.trim().length > 0 && !/^[A-Fa-f]$/.test(originalAnswer.trim())
  );

  // ── 表现与能量 ──
  let judgementCorrect = $derived(spiritIsWrong && spiritVerdict === 'wrong');

  let energyReward = $derived.by(() => {
    if (!childGraded) return 0;
    if (!childCorrect) return 3;
    if (!spiritIsWrong) return 8;
    return judgementCorrect ? 8 : 5;
  });

  let performanceText = $derived.by(() => {
    if (!childCorrect) return '新题没做对，不过你认真当了一次小老师，先看看正确思路吧！';
    if (!spiritIsWrong) return '新题自己做对了，太棒了！';
    return judgementCorrect
      ? '新题自己做对了，还一眼看出小精灵答错了，真是厉害的小老师！'
      : '新题自己做对了，不过小精灵其实答错了，下次再仔细检查哦！';
  });

  let spiritExplainText = $derived.by(() => {
    if (!spiritIsWrong) return '小精灵说它也不确定，需要你来教它！';
    if (isChoice) {
      return `小精灵选了「${spiritAnswer}」，正确答案是「${correctDisplay}」，它选错选项啦。`;
    }
    return `小精灵答成了「${spiritAnswer}」，正确答案是「${correctDisplay}」，它算错/写错啦。`;
  });

  // ── 加载变式题 ──
  async function loadVariant() {
    loading = true;
    error = '';
    try {
      const data = await generateVariant(nodeId, originalQuestionId);
      if (!data) {
        failStep('没能生成新题目，我们可以跳过这一步。');
        return;
      }
      // 兜底：绝不让"没有选项的选择题"出现在孩子面前
      if (data.questionType === 'MULTIPLE_CHOICE' && parseOptions(data.options).length === 0) {
        failStep('这道新题的选项没有准备好，我们可以跳过这一步。');
        return;
      }
      // 同理：专用输入组件要的数据没准备好时，别让孩子对着一道没法作答的题发呆
      if (data.questionType === 'POEM_SEQUENCE' && parsePoemLines(data.options).length === 0) {
        failStep('这道排序题的选项没有准备好，我们可以跳过这一步。');
        return;
      }
      if (data.questionType === 'VOCAB_MATCH' && !parseVocabOptions(data.options)) {
        failStep('这道配对题的选项没有准备好，我们可以跳过这一步。');
        return;
      }
      variant = data;
      step = 'show_variant';
    } catch (e: any) {
      failStep(e?.message ? `${e.message}，我们可以跳过这一步。` : '生成新题目失败，我们可以跳过这一步。');
    } finally {
      loading = false;
    }
  }

  function failStep(message: string) {
    error = message;
    step = 'failed';
  }

  // ── 判孩子的答案 ──
  function confirmChildAnswer() {
    if (!canConfirm || childGraded) return;
    if (isChoice) {
      const selected = parsedOptions.find((o) => o.key === selectedOption);
      if (correctOption && normalize(selectedOption) === normalize(correctOption.key)) {
        childCorrect = true;
      } else if (selected && correctOption) {
        childCorrect = isAnswerCorrect(selected.text, correctOption.text);
      } else if (selected) {
        childCorrect = isAnswerCorrect(selected.text, correctRaw);
      } else {
        childCorrect = false;
      }
    } else {
      // 判断题(true/false)、填空题、数字输入，以及三个专用组件回报的答案
      childCorrect = checkAnswer(childRawValue, correctRaw, variantType);
    }
    childGraded = true;
    buildSpiritAnswer();
  }

  // ── 小精灵的答案必须确实是错的；构造不出来就不判定对错 ──
  function buildSpiritAnswer() {
    spiritVerdict = '';
    spiritIsWrong = false;
    spiritAnswer = '';

    if (isChoice) {
      if (!correctOption) {
        markSpiritUnsure();
        return;
      }
      const correctKey = correctOption.key;
      const correctText = correctOption.text;
      const wrongOptions = parsedOptions.filter(
        (o) =>
          normalize(o.key) !== normalize(correctKey) &&
          !isAnswerCorrect(o.text, correctText) &&
          !isAnswerCorrect(o.text, correctRaw)
      );
      if (wrongOptions.length === 0) {
        markSpiritUnsure();
        return;
      }
      const pick = wrongOptions[Math.floor(Math.random() * wrongOptions.length)];
      spiritAnswer = `${pick.key}. ${pick.text}`;
      spiritIsWrong = true;
      return;
    }

    const correctNum = asNumber(correctRaw);
    const candidates: string[] = [];
    if (correctNum !== null) {
      // 数字题：±1 / ±2
      candidates.push(
        String(correctNum + 1),
        String(correctNum - 1),
        String(correctNum + 2),
        String(correctNum - 2)
      );
    } else {
      const text = correctRaw;
      if (text.length >= 2) {
        candidates.push(swapLastTwo(text), text.slice(0, -1));
      }
      if (/\d/.test(text)) {
        candidates.push(text.replace(/\d/, (d) => String((Number(d) + 1) % 10)));
      }
    }

    const wrong = candidates.find((c) => c !== correctRaw && !checkAnswer(c, correctRaw, variantType));
    if (!wrong) {
      markSpiritUnsure();
      return;
    }
    spiritAnswer = wrong;
    spiritIsWrong = true;
  }

  function swapLastTwo(text: string): string {
    return `${text.slice(0, -2)}${text.slice(-1)}${text.slice(-2, -1)}`;
  }

  function markSpiritUnsure() {
    spiritAnswer = '我也不确定，你来教我！';
    spiritIsWrong = false;
  }

  // ── 流程控制 ──
  function goToSpirit() {
    step = spiritIsWrong ? 'spirit_judge' : 'spirit_explain';
  }

  function judgeSpirit(verdict: 'right' | 'wrong') {
    spiritVerdict = verdict;
    step = 'spirit_explain';
  }

  function finish() {
    onComplete(true, energyReward);
  }

  function skipStep() {
    onComplete(false, 0);
  }
</script>

<div class="learn-by-analogy bg-white rounded-2xl shadow-lg p-5 border-2 border-amber-300">
  {#if step === 'intro'}
    <div class="text-center">
      <span class="text-4xl mb-3 block">💡</span>
      <h3 class="text-lg font-bold text-gray-800 mb-2">你能出一道新题吗？</h3>
      <p class="text-sm text-gray-600 mb-4">
        你刚解决了：<strong>{originalText}</strong>
      </p>
      <p class="text-sm text-gray-500 mb-4">
        现在试试改变数字，创造一道新题目，然后再当一次小老师吧！
      </p>
      <button onclick={loadVariant} disabled={loading}
        class="px-6 py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white font-bold rounded-xl hover:from-amber-500 hover:to-orange-600 transition active:scale-95 shadow-md disabled:opacity-50">
        {loading ? '加载中...' : '✨ 生成新题目'}
      </button>
    </div>

  {:else if step === 'failed'}
    <div class="text-center">
      <span class="text-4xl mb-3 block">🌱</span>
      <h3 class="text-lg font-bold text-gray-800 mb-2">这一步没准备好</h3>
      <p class="text-sm text-red-600 mb-4">{error || '生成新题目失败，我们可以跳过这一步。'}</p>
      <button onclick={skipStep}
        class="px-6 py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white font-bold rounded-xl hover:from-amber-500 hover:to-orange-600 transition active:scale-95 shadow-md">
        跳过这一步 / 继续 →
      </button>
    </div>

  {:else if step === 'show_variant' && variant}
    <div>
      <div class="bg-amber-50 rounded-xl p-4 mb-4">
        <p class="text-xs text-amber-600 font-medium mb-1">原题：{variant?.originalText ?? originalText}</p>
        <p class="text-lg font-bold text-gray-800">新题：{variant?.questionText}</p>
      </div>

      {#if isSceneOnly}
        <!-- 场景组件类：它们自行按题号向后端提交答案，变式题没有题号 → 不判分，只如实展示 -->
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-3">
          <p class="text-sm text-blue-800 font-medium mb-1">🌟 这道题要在闯关场景里动手完成</p>
          <p class="text-xs text-blue-600">
            这一步是变式练习，没法把那个场景搬过来，所以不判分——直接看看答案就好。
          </p>
        </div>
        <div class="bg-amber-50 rounded-xl p-4 mb-4 text-sm">
          <p class="text-gray-800 font-medium mb-1">{variant?.questionText}</p>
          <p class="text-gray-700">正确答案：<strong>{correctDisplay}</strong></p>
          {#if variant?.explanation}
            <p class="text-gray-600 mt-2">📖 解析：{variant.explanation}</p>
          {/if}
        </div>
        <button onclick={skipStep}
          class="w-full py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white font-bold rounded-xl hover:from-amber-500 hover:to-orange-600 transition active:scale-95 shadow-md">
          看懂了，继续 →
        </button>
      {:else}
        {#if isChoice}
          <p class="text-sm text-gray-600 mb-2">先自己答一答这道新题：</p>
          <div class="space-y-2">
            {#each parsedOptions as opt, i (i)}
              <button onclick={() => (selectedOption = opt.key)} disabled={childGraded}
                class={['w-full text-left px-4 py-3 rounded-xl border-2 transition text-sm',
                  childGraded && correctOption?.key === opt.key
                    ? 'border-green-500 bg-green-50'
                    : childGraded && selectedOption === opt.key
                      ? 'border-red-400 bg-red-50'
                      : selectedOption === opt.key
                        ? 'border-amber-500 bg-amber-50'
                        : 'border-gray-200 hover:border-amber-300'].join(' ')}>
                <span class="font-medium">{opt.key}.</span> {opt.text}
              </button>
            {/each}
          </div>
        {:else if isTrueFalse}
          <p class="text-sm text-gray-600 mb-2">先自己判断一下这道新题：</p>
          <div class="grid grid-cols-2 gap-3">
            <button onclick={() => (selectedOption = 'true')} disabled={childGraded}
              class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                childGraded && normalize(correctRaw) === 'true'
                  ? 'border-green-500 bg-green-50 text-green-700'
                  : selectedOption === 'true'
                    ? 'border-amber-500 bg-amber-50 text-amber-800'
                    : 'border-gray-200 hover:border-amber-300 text-gray-700'].join(' ')}>
              ✓ 正确
            </button>
            <button onclick={() => (selectedOption = 'false')} disabled={childGraded}
              class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                childGraded && normalize(correctRaw) === 'false'
                  ? 'border-green-500 bg-green-50 text-green-700'
                  : selectedOption === 'false'
                    ? 'border-amber-500 bg-amber-50 text-amber-800'
                    : 'border-gray-200 hover:border-amber-300 text-gray-700'].join(' ')}>
              ✗ 错误
            </button>
          </div>
        {:else if useComponentInput && variantType === 'MATH_INPUT'}
          <p class="text-sm text-gray-600 mb-2">先自己答一答这道新题：</p>
          <MathInput disabled={childGraded} onSelect={(v) => (componentAnswer = v)} />
        {:else if useComponentInput && variantType === 'POEM_SEQUENCE'}
          <p class="text-sm text-gray-600 mb-2">把诗句按正确顺序排好吧：</p>
          <PoemSequence options={poemLines} disabled={childGraded}
            onSelect={(v) => (componentAnswer = v)} />
        {:else if useComponentInput && variantType === 'VOCAB_MATCH' && vocabOptions}
          <p class="text-sm text-gray-600 mb-2">把单词和释义配对起来吧：</p>
          <VocabMatch options={vocabOptions} disabled={childGraded}
            onSelect={(v) => (componentAnswer = v)} />
        {:else}
          <div class="mb-4">
            <label class="text-sm text-gray-600 mb-1 block" for="analogy-answer">答案是多少？</label>
            <input id="analogy-answer" type="text" bind:value={fillAnswer} disabled={childGraded}
              placeholder="输入你的答案..."
              class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-amber-500 outline-none transition text-lg" />
          </div>
        {/if}

        {#if childGraded}
          <div class={['mt-4 rounded-xl p-4 border-2',
            childCorrect ? 'bg-green-50 border-green-300' : 'bg-orange-50 border-orange-300'].join(' ')}>
            {#if childCorrect}
              <p class="font-bold text-green-700">✅ 答对了！</p>
            {:else}
              <p class="font-bold text-orange-700">💪 这次没答对，正确答案是：<strong>{correctDisplay}</strong></p>
            {/if}
            <p class="text-sm text-gray-600 mt-1">你的答案：{childAnswerDisplay || '（空）'}</p>
            {#if variant?.explanation}
              <p class="text-sm text-gray-600 mt-2">📖 解析：{variant.explanation}</p>
            {/if}
          </div>
          <button onclick={goToSpirit}
            class="mt-4 w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-500 text-white font-bold rounded-xl hover:from-blue-600 hover:to-indigo-600 transition active:scale-95 shadow-md">
            🤖 下一步：看看小精灵的答案 →
          </button>
        {:else}
          <div class="mt-4">
            <button onclick={confirmChildAnswer} disabled={!canConfirm}
              class="w-full py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl disabled:from-gray-300 disabled:text-gray-400 transition active:scale-95">
              ✅ 确认答案
            </button>
          </div>
        {/if}
      {/if}
    </div>

  {:else if step === 'spirit_judge'}
    <div>
      <div class="bg-blue-50 rounded-xl p-4 mb-4">
        <div class="flex items-center gap-2 mb-2">
          <span class="text-2xl">🤖</span>
          <span class="text-sm font-medium text-blue-700">小精灵说：</span>
        </div>
        <p class="text-2xl font-bold text-blue-800">"我觉得答案是 {spiritAnswer}！"</p>
      </div>
      <p class="text-sm text-gray-600 mb-3">请当一次小老师：小精灵答对了吗？</p>
      <div class="flex gap-2">
        <button onclick={() => judgeSpirit('right')}
          class="flex-1 py-3 bg-green-100 text-green-700 font-bold rounded-xl hover:bg-green-200 transition active:scale-95">
          👍 小精灵答对了
        </button>
        <button onclick={() => judgeSpirit('wrong')}
          class="flex-1 py-3 bg-red-100 text-red-700 font-bold rounded-xl hover:bg-red-200 transition active:scale-95">
          👎 小精灵答错了
        </button>
      </div>
    </div>

  {:else if step === 'spirit_explain'}
    <div>
      <div class="bg-blue-50 rounded-xl p-4 mb-3">
        <p class="text-xs font-medium text-blue-700 mb-1">小精灵的答案</p>
        <p class="text-lg font-bold text-blue-800">
          {spiritIsWrong ? spiritAnswer : '我也不确定，你来教我！'}
        </p>
      </div>

      {#if spiritIsWrong && spiritVerdict}
        <p class={['text-sm mb-3', judgementCorrect ? 'text-green-700' : 'text-orange-700'].join(' ')}>
          {judgementCorrect
            ? '✅ 判断正确！小精灵确实答错了。'
            : `💪 其实小精灵答错了：它答成了「${spiritAnswer}」。`}
        </p>
      {/if}

      <label class="text-sm text-gray-600 mb-1 block" for="analogy-reason">
        {spiritIsWrong
          ? '用你自己的话说说：小精灵哪里想错了？（也可以跳过）'
          : '小精灵也拿不准，你来用自己的话教教它吧！（也可以跳过）'}
      </label>
      <textarea id="analogy-reason" bind:value={childReason} rows="3"
        placeholder="例如：它把加号当成减号了……"
        class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-amber-500 outline-none transition text-sm"></textarea>

      <div class="flex gap-2 mt-4">
        <button onclick={() => (step = 'result')}
          class="px-4 py-3 bg-gray-100 text-gray-600 font-medium rounded-xl hover:bg-gray-200 transition text-sm">
          跳过理由
        </button>
        <button onclick={() => (step = 'result')} disabled={!childReason.trim()}
          class="flex-1 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl disabled:from-gray-300 disabled:text-gray-400 transition active:scale-95">
          📝 提交理由，继续 →
        </button>
      </div>
    </div>

  {:else if step === 'result'}
    <div>
      <div class="text-center mb-4">
        <span class="text-5xl mb-2 block animate-bounce">{childCorrect ? '🎉' : '🌱'}</span>
        <h3 class={['text-lg font-bold', childCorrect ? 'text-green-700' : 'text-amber-700'].join(' ')}>
          {childCorrect ? '太棒了，小老师！' : '没关系，小老师！'}
        </h3>
      </div>

      <div class="bg-amber-50 rounded-xl p-4 mb-3 text-sm space-y-1">
        <p class="text-xs text-amber-600">原题：{variant?.originalText ?? originalText}</p>
        <p class="text-gray-800 font-medium">新题：{variant?.questionText}</p>
        <p class="text-gray-700">正确答案：<strong>{correctDisplay}</strong></p>
        <p class="text-gray-700">我的答案：{childAnswerDisplay || '（空）'} {childCorrect ? '✅' : '❌'}</p>
        {#if showOriginalAnswer}
          <p class="text-gray-500">原题答案：{originalAnswer}</p>
        {/if}
      </div>

      <div class="bg-blue-50 rounded-xl p-3 mb-3 text-sm text-blue-800">
        <p class="font-medium mb-1">{spiritIsWrong ? '小精灵错在哪：' : '小精灵的表现：'}</p>
        <p>{spiritExplainText}</p>
        {#if spiritIsWrong}
          <p class="mt-1">{judgementCorrect ? '你成功抓住了它的错误！' : '这次没看出它的错，下次仔细检查哦～'}</p>
        {/if}
      </div>

      {#if childReason.trim()}
        <div class="bg-purple-50 rounded-xl p-3 mb-3 text-sm text-purple-800">
          <p class="font-medium mb-1">你的讲解：</p>
          <p>{childReason.trim()}</p>
        </div>
      {/if}

      <div class="bg-gradient-to-r from-amber-100 to-yellow-100 rounded-xl p-3 mb-4 border border-amber-300">
        <p class="text-sm text-amber-800 mb-1">{performanceText}</p>
        <p class="text-sm font-bold text-amber-700">⚡ +{energyReward} 能量获得！</p>
      </div>

      <button onclick={finish}
        class="w-full px-6 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl hover:from-green-600 hover:to-emerald-600 transition active:scale-95 shadow-md">
        继续 →
      </button>
    </div>
  {/if}

  {#if error && step !== 'failed'}
    <div class="mt-3 bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">{error}</div>
  {/if}
</div>
