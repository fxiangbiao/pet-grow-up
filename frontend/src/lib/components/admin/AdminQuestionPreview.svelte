<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';
  import type { QuestionDTO } from '$lib/api/study';
  import SceneTap from '$lib/components/study/SceneTap.svelte';
  import SceneMatch from '$lib/components/study/SceneMatch.svelte';
  import SceneMathTen from '$lib/components/study/SceneMathTen.svelte';
  import ScenePinyinBubble from '$lib/components/study/ScenePinyinBubble.svelte';
  import SceneCharBuild from '$lib/components/study/SceneCharBuild.svelte';
  import SceneClock from '$lib/components/study/SceneClock.svelte';
  import SceneShop from '$lib/components/study/SceneShop.svelte';
  import SceneWhackMole from '$lib/components/study/SceneWhackMole.svelte';
  import SceneShapePuzzle from '$lib/components/study/SceneShapePuzzle.svelte';
  import MathInput from '$lib/components/study/MathInput.svelte';
  import VocabMatch from '$lib/components/study/VocabMatch.svelte';
  import PoemSequence from '$lib/components/study/PoemSequence.svelte';

  let {
    questionData,
  }: {
    questionData: CreateQuestion;
  } = $props();

  function parseVocabOptions(): { left: { id: string; text: string }[]; right: { id: string; text: string }[] } {
    try {
      if (questionData.options) {
        const parsed = JSON.parse(questionData.options);
        return {
          left: parsed.left || [],
          right: parsed.right || [],
        };
      }
    } catch { /* fall through */ }
    return { left: [], right: [] };
  }

  function parsePoemLines(): string[] {
    try {
      if (questionData.options) {
        const parsed = JSON.parse(questionData.options);
        if (Array.isArray(parsed)) return parsed.map((l: any) => typeof l === 'string' ? l : l.text || '');
      }
    } catch { /* fall through */ }
    // Fallback: split questionText by Chinese punctuation
    return (questionData.questionText || '').split(/[,，。、；;]/).filter(Boolean);
  }

  let question = $derived.by(() => {
    const _type = questionData.questionType;
    const _text = questionData.questionText;
    const _opts = questionData.options;
    const _pts = questionData.points;
    return {
      sessionId: 0,
      questionId: 0,
      questionType: _type,
      questionText: _text || '(未填写题目文本)',
      options: _opts || null,
      points: _pts || 10,
    } as QuestionDTO;
  });

  // Force re-mount scene components when form data changes, so their
  // non-reactive `const` initializers (parseOptions etc.) re-run with fresh props.
  let remountKey = $derived(
    questionData.questionType + '|' +
    (questionData.options ?? '') + '|' +
    (questionData.questionText ?? '') + '|' +
    (questionData.correctAnswer ?? '')
  );
  let noop = () => {};
  let vocabOpts = $derived.by(() => parseVocabOptions());
  let poemLines = $derived.by(() => parsePoemLines());

  function typeLabel(t: string): string {
    const map: Record<string, string> = {
      MULTIPLE_CHOICE: '选择题', SCENE_TAP: '泡泡点击', SCENE_PINYIN: '拼音泡泡',
      FILL_BLANK: '填空题', MATH_INPUT: '数字输入', SCENE_DRAG: '拖拽凑十',
      SCENE_MATCH: '图形配对', SCENE_CLOCK: '拨钟表', SCENE_SHOP: '宠物商店',
      SCENE_CHAR_BUILD: '汉字拼装', SCENE_WHACK_MOLE: '打地鼠',
      VOCAB_MATCH: '单词配对', POEM_SEQUENCE: '诗句排序', SCENE_SHAPE_PUZZLE: '拼图工坊'
    };
    return map[t] || t;
  }
</script>

<div class="bg-gradient-to-br from-indigo-50 to-purple-50 rounded-xl border-2 border-dashed border-indigo-200 p-4 min-h-[320px]">
  <!-- Header -->
  <div class="flex items-center justify-between mb-3">
    <span class="text-xs font-bold text-indigo-500 uppercase tracking-wider">📱 实时预览</span>
    <span class="text-[10px] bg-indigo-100 text-indigo-600 px-2 py-0.5 rounded-full">{typeLabel(questionData.questionType)}</span>
  </div>

  <!-- Preview area: scaled container -->
  <div class="bg-white rounded-lg shadow-inner border border-gray-100 overflow-hidden" style="max-height: 400px;">
    <div style="transform: scale(0.75); transform-origin: top center;">
      {#if questionData.questionType === 'FILL_BLANK'}
        <!-- Inline FILL_BLANK preview -->
        <div class="p-6">
          <p class="text-lg text-gray-800 mb-3">{questionData.questionText || '(未填写)'}</p>
          <div class="flex items-center gap-2">
            <span class="text-sm text-gray-500">答案：</span>
            <span class="px-3 py-1.5 bg-green-100 text-green-800 border-2 border-dashed border-green-400 rounded-lg text-lg font-mono">
              {questionData.correctAnswer || '(未填写)'}
            </span>
          </div>
        </div>
      {:else if questionData.questionType === 'MULTIPLE_CHOICE' || questionData.questionType === 'SCENE_TAP'}
        {#key remountKey}
          <SceneTap question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_PINYIN'}
        {#key remountKey}
          <ScenePinyinBubble question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_MATCH'}
        {#key remountKey}
          <SceneMatch question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'MATH_INPUT'}
        {#key remountKey}
          <MathInput disabled={true} onSelect={noop} />
        {/key}
      {:else if questionData.questionType === 'SCENE_DRAG'}
        {#key remountKey}
          <SceneMathTen question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_CLOCK'}
        {#key remountKey}
          <SceneClock question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_SHOP'}
        {#key remountKey}
          <SceneShop question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_CHAR_BUILD'}
        {#key remountKey}
          <SceneCharBuild question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'SCENE_WHACK_MOLE'}
        {#key remountKey}
          <SceneWhackMole question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else if questionData.questionType === 'VOCAB_MATCH'}
        {#key remountKey}
          <VocabMatch options={vocabOpts} disabled={true} onSelect={noop} />
        {/key}
      {:else if questionData.questionType === 'POEM_SEQUENCE'}
        {#key remountKey}
          <PoemSequence options={poemLines} disabled={true} onSelect={noop} />
        {/key}
      {:else if questionData.questionType === 'SCENE_SHAPE_PUZZLE'}
        {#key remountKey}
          <SceneShapePuzzle question={question} sessionId={0} onComplete={noop} preview={true} />
        {/key}
      {:else}
        <!-- Fallback: simple text display -->
        <div class="p-6 text-center">
          <p class="text-gray-600 text-sm mb-2">{questionData.questionText || '(未填写题目文本)'}</p>
          {#if questionData.correctAnswer}
            <span class="inline-block px-3 py-1.5 bg-green-100 text-green-800 rounded-lg text-sm font-mono">
              答案：{questionData.correctAnswer}
            </span>
          {/if}
        </div>
      {/if}
    </div>
  </div>

  <!-- Hint: interactive preview disabled -->
  <p class="text-[10px] text-gray-400 text-center mt-2">预览模式下交互已禁用，仅展示视觉效果</p>
</div>
