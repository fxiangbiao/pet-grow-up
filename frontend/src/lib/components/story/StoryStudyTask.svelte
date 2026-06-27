<script lang="ts">
  import { onMount } from 'svelte';
  import { startSession, submitAnswer, getWorldMap } from '$lib/api/study';
  import type { QuestionDTO, AnswerResult } from '$lib/api/study';
  import type { StudyResult } from '$lib/api/story';
  import CorrectIndicator from '$lib/components/feedback/CorrectIndicator.svelte';
  import WrongIndicator from '$lib/components/feedback/WrongIndicator.svelte';
  import PoemSequence from '$lib/components/study/PoemSequence.svelte';
  import MathInput from '$lib/components/study/MathInput.svelte';
  import VocabMatch from '$lib/components/study/VocabMatch.svelte';
  import HpBar from '$lib/components/study/HpBar.svelte';
  import ComboCounter from '$lib/components/study/ComboCounter.svelte';
  import AdventurePath from '$lib/components/study/AdventurePath.svelte';
  import BossSection from '$lib/components/study/BossSection.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    subject = 'chinese',
    npcName = '',
    chapterTitle = '',
    onComplete = (_result: StudyResult) => {},
    onCancel = () => {}
  }: {
    subject?: string;
    npcName?: string;
    chapterTitle?: string;
    onComplete?: (result: StudyResult) => void;
    onCancel?: () => void;
  } = $props();

  // Study state
  let phase = $state<'loading' | 'playing' | 'error'>('loading');
  let question = $state<QuestionDTO | null>(null);
  let sessionId = $state<number>(0);
  let selectedAnswer = $state('');
  let submitted = $state(false);
  let lastResult = $state<AnswerResult | null>(null);
  let totalQuestions = $state(3);
  let answeredCount = $state(0);
  let questionStartTime = $state<number>(0);
  let errorMsg = $state('');

  // Adventure state (3 HP, 3 questions)
  let hp = $state(3);
  let combo = $state(0);
  let maxCombo = $state(0);
  let bossDefeated = $state(false);
  let bossThemePlayed = $state(false);
  let treasuresFound = $state(0);
  let results = $state<Array<boolean | null>>([]);
  let adventureEnded = $state(false);

  const isLastQuestion = $derived(answeredCount >= totalQuestions - 1);

  // Boss theme on last question
  $effect(() => {
    if (isLastQuestion && phase === 'playing' && !bossThemePlayed) {
      soundManager.playBossTheme();
      bossThemePlayed = true;
    }
  });

  const subjectTheme = $derived.by(() => {
    const themes: Record<string, { border: string; bg: string; accent: string }> = {
      chinese: { border: 'border-amber-300', bg: 'bg-amber-50', accent: 'text-amber-700' },
      math: { border: 'border-blue-300', bg: 'bg-blue-50', accent: 'text-blue-700' },
      english: { border: 'border-purple-300', bg: 'bg-purple-50', accent: 'text-purple-700' }
    };
    return themes[subject] || themes.chinese;
  });

  onMount(async () => {
    soundManager.playBGM(subject);
    try {
      const world = await getWorldMap(subject);
      const node = world.nodes.find((n: any) => n.isUnlocked || true) || world.nodes[0];
      if (!node) throw new Error('该学科暂无可用知识节点');

      const result = await startSession({
        subject,
        sessionType: 'STORY',
        difficultyLevel: 1,
        knowledgeNodeId: node.nodeId
      });

      sessionId = result.sessionId;
      question = result;
      totalQuestions = result.totalQuestions ?? 3;
      answeredCount = result.answeredCount ?? 0;
      results = Array(totalQuestions).fill(null);
      phase = 'playing';
      questionStartTime = Date.now();
    } catch (e: any) {
      errorMsg = e.message || '启动学习失败';
      phase = 'error';
    }
  });

  function selectAnswer(answer: string) {
    if (submitted) return;
    selectedAnswer = answer;
  }

  async function handleSubmit() {
    if (!selectedAnswer || submitted || !question || adventureEnded) return;
    submitted = true;
    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: selectedAnswer,
        timeSpent: Math.max(0, Math.floor((Date.now() - questionStartTime) / 1000))
      });
      lastResult = result;
      results[answeredCount] = result.isCorrect;

      if (result.isCorrect) {
        combo++;
        maxCombo = Math.max(maxCombo, combo);
        if (combo >= 2 && combo % 2 === 0) {
          treasuresFound++;
          soundManager.playTreasure();
        }
        if (result.isLastQuestion && result.isCorrect) {
          bossDefeated = true;
          soundManager.playBossDefeated();
        }
      } else {
        combo = 0;
        if (result.isLastQuestion) {
          hp -= 2;
        } else {
          hp -= 1;
        }
        if (hp <= 0) {
          adventureEnded = true;
          setTimeout(finish, 2000);
          return;
        }
      }

      if (result.isSessionComplete) {
        setTimeout(finish, 2000);
      } else if (result.nextQuestion) {
        const nextQ = result.nextQuestion;
        setTimeout(() => {
          question = nextQ;
          answeredCount = nextQ.answeredCount ?? answeredCount + 1;
          submitted = false;
          selectedAnswer = '';
          lastResult = null;
          questionStartTime = Date.now();
        }, 1500);
      }
    } catch (e: any) {
      errorMsg = e.message;
      submitted = false;
    }
  }

  function finish() {
    soundManager.stopBGM();
    onComplete({
      passed: hp > 0,
      totalQuestions,
      correctAnswers: results.filter(r => r === true).length,
      accuracy: results.length > 0 ? results.filter(r => r === true).length / results.length : 0,
      maxCombo,
      bossDefeated,
      treasuresFound,
      finalHp: Math.max(hp, 0)
    });
  }

  function skip() {
    soundManager.stopBGM();
    onComplete({ passed: true, totalQuestions: 0, correctAnswers: 0, accuracy: 0, maxCombo: 0, bossDefeated: false, treasuresFound: 0, finalHp: 3 });
  }

  // Parsed options
  let parsedOptions = $derived.by(() => {
    if (!question?.options) return [];
    try { return JSON.parse(question.options) as Array<{ key: string; text: string }>; }
    catch { return []; }
  });

  let parsedVocabOptions = $derived.by(() => {
    if (!question?.options || question.questionType !== 'VOCAB_MATCH') return null;
    try { return JSON.parse(question.options) as { left: Array<{ id: string; text: string }>; right: Array<{ id: string; text: string }>; }; }
    catch { return null; }
  });

  let parsedPoemLines = $derived.by(() => {
    if (!question?.options || question.questionType !== 'POEM_SEQUENCE') return [];
    try { return JSON.parse(question.options) as string[]; }
    catch { return []; }
  });

  function onNewTypeAnswer(answer: string) {
    selectedAnswer = answer;
    handleSubmit();
  }
</script>

<!-- Loading -->
{#if phase === 'loading'}
  <div class="text-center py-8">
    <div class="text-3xl mb-3 animate-bounce">📖</div>
    <p class="text-gray-500 text-sm">正在准备{chapterTitle}的挑战...</p>
  </div>

<!-- Error -->
{:else if phase === 'error'}
  <div class="text-center py-8">
    <div class="text-4xl mb-3">😅</div>
    <p class="text-gray-600 text-sm mb-4">{errorMsg || '暂时没有可用的题目'}</p>
    <button onclick={skip}
      class="px-6 py-2 bg-indigo-500 text-white rounded-lg text-sm hover:bg-indigo-600 transition">
      跳过挑战，继续剧情
    </button>
  </div>

<!-- Playing -->
{:else if phase === 'playing' && question}
  <div class="bg-white rounded-xl border-2 {subjectTheme.border}">
    <!-- Mini header: HP + Combo -->
    <div class="flex items-center justify-between px-4 pt-3 pb-1">
      <HpBar {hp} maxHp={3} />
      <ComboCounter {combo} />
    </div>

    <!-- Adventure path (compact) -->
    <div class="bg-gray-50 mx-3 rounded-lg mb-2 scale-90 origin-top">
      <AdventurePath
        totalQuestions={totalQuestions}
        currentIndex={answeredCount}
        results={results}
        species={spiritStore.activeSpirit?.species ?? null}
        evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
        subjectTheme={subject}
      />
    </div>

    <!-- Boss section -->
    {#if isLastQuestion}
      <div class="mx-3 mb-2">
        <BossSection visible={true} {bossDefeated} {subject} />
      </div>
    {/if}

    <!-- Question -->
    <div class="px-4 pb-4">
      <p class="text-sm font-medium text-gray-800 mb-3">{question.questionText}</p>

      {#if question.questionType === 'MULTIPLE_CHOICE'}
        <div class="space-y-1.5">
          {#each parsedOptions as opt}
            <button onclick={() => selectAnswer(opt.key)} disabled={submitted}
              class={['w-full text-left px-3 py-2.5 rounded-lg border-2 transition text-sm',
                selectedAnswer === opt.key ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300'
              ].join(' ')}>
              <span class="font-medium">{opt.key}.</span> {opt.text}
            </button>
          {/each}
        </div>
      {:else if question.questionType === 'FILL_BLANK'}
        <input type="text" bind:value={selectedAnswer} disabled={submitted}
               placeholder="输入你的答案..."
               class="w-full px-3 py-2.5 border-2 border-gray-200 rounded-lg focus:border-indigo-500 outline-none transition text-sm" />
      {:else if question.questionType === 'TRUE_FALSE'}
        <div class="grid grid-cols-2 gap-3">
          <button onclick={() => selectAnswer('true')} disabled={submitted}
            class={['py-3 rounded-lg border-2 text-center transition font-medium',
              selectedAnswer === 'true' ? 'border-green-500 bg-green-50 text-green-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>
            ✓ 正确
          </button>
          <button onclick={() => selectAnswer('false')} disabled={submitted}
            class={['py-3 rounded-lg border-2 text-center transition font-medium',
              selectedAnswer === 'false' ? 'border-red-500 bg-red-50 text-red-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>
            ✗ 错误
          </button>
        </div>
      {:else if question.questionType === 'POEM_SEQUENCE'}
        <PoemSequence options={parsedPoemLines} disabled={submitted} onSelect={onNewTypeAnswer} />
      {:else if question.questionType === 'MATH_INPUT'}
        <MathInput disabled={submitted} onSelect={(v) => { selectedAnswer = v; }} />
      {:else if question.questionType === 'VOCAB_MATCH'}
        {#if parsedVocabOptions}
          <VocabMatch options={parsedVocabOptions} disabled={submitted} onSelect={onNewTypeAnswer} />
        {/if}
      {/if}

      {#if !submitted && question.questionType !== 'POEM_SEQUENCE' && question.questionType !== 'VOCAB_MATCH'}
        <button onclick={handleSubmit} disabled={!selectedAnswer}
                class="mt-3 w-full py-2.5 bg-indigo-500 text-white rounded-lg font-semibold hover:bg-indigo-600 disabled:opacity-50 transition text-sm">
          提交答案
        </button>
      {/if}
    </div>
  </div>

  <!-- Feedback -->
  {#if lastResult}
    <div class="mt-2 scale-90 origin-top">
      {#if lastResult.isCorrect}
        <CorrectIndicator {combo} isBoss={lastResult.isLastQuestion} />
      {:else}
        <WrongIndicator correctAnswer={lastResult.correctAnswer} explanation={lastResult.explanation} isBoss={lastResult.isLastQuestion} />
      {/if}
    </div>
  {/if}
{/if}
