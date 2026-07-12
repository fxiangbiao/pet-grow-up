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
  import SceneMathTen from '$lib/components/study/SceneMathTen.svelte';
  import SceneTap from '$lib/components/study/SceneTap.svelte';
  import SceneMatch from '$lib/components/study/SceneMatch.svelte';
  import SceneWhackMole from '$lib/components/study/SceneWhackMole.svelte';
  import SceneShapePuzzle from '$lib/components/study/SceneShapePuzzle.svelte';
  import SceneClock from '$lib/components/study/SceneClock.svelte';
  import SceneShop from '$lib/components/study/SceneShop.svelte';
  import ScenePinyinBubble from '$lib/components/study/ScenePinyinBubble.svelte';
  import SceneCharBuild from '$lib/components/study/SceneCharBuild.svelte';
  import EnergyBar from '$lib/components/study/EnergyBar.svelte';
  import ComboCounter from '$lib/components/study/ComboCounter.svelte';
  import BattleScene from '$lib/components/study/BattleScene.svelte';
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

  // Adventure state (purification)
  let energy = $state(100);
  let combo = $state(0);
  let maxCombo = $state(0);
  let guardianPurified = $state(false);
  let guardianThemePlayed = $state(false);
  let treasuresFound = $state(0);
  let results = $state<Array<boolean | null>>([]);

  // Purify state
  let purifyState = $state<'idle' | 'player_purify' | 'enemy_encourage' | 'guardian_purified'>('idle');
  let spiritMood = $state<'idle' | 'happy' | 'excited' | 'hurt'>('idle');

  const isLastQuestion = $derived(answeredCount >= totalQuestions - 1);

  // Guardian theme on last question
  $effect(() => {
    if (isLastQuestion && phase === 'playing' && !guardianThemePlayed) {
      soundManager.playBossTheme?.();
      guardianThemePlayed = true;
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
      spiritStore.recordInteraction(); // wake up spirit
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

  function triggerPurifyAnimation(isCorrect: boolean, isLast: boolean) {
    if (isCorrect) {
      purifyState = 'player_purify';
      spiritMood = 'happy';
      soundManager.playCorrect?.();
    } else {
      purifyState = 'enemy_encourage';
      spiritMood = 'hurt';
      soundManager.playWrong?.();
    }
    setTimeout(() => {
      if (isLast && isCorrect) {
        purifyState = 'guardian_purified';
      } else if (!isLast || isCorrect) {
        purifyState = 'idle';
        spiritMood = 'idle';
      }
    }, 700);
  }

  async function handleSubmit() {
    if (!selectedAnswer || submitted || !question) return;
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

      triggerPurifyAnimation(result.isCorrect, result.isLastQuestion);

      if (result.isCorrect) {
        combo++;
        maxCombo = Math.max(maxCombo, combo);
        if (combo >= 3) spiritMood = 'excited';
        energy = Math.min(100, energy + 10);
        if (combo >= 2 && combo % 2 === 0) {
          treasuresFound++;
          soundManager.playTreasure?.();
        }
        if (result.isLastQuestion && result.isCorrect) {
          guardianPurified = true;
          soundManager.playBossDefeated?.();
        }
      } else {
        combo = 0;
        // No HP loss — just visual flash
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
        }, 1000);
      }
    } catch (e: any) {
      errorMsg = e.message;
      submitted = false;
    }
  }

  function finish() {
    soundManager.stopBGM();
    onComplete({
      passed: true, // always pass — no death in purification
      totalQuestions,
      correctAnswers: results.filter(r => r === true).length,
      accuracy: results.length > 0 ? results.filter(r => r === true).length / results.length : 0,
      maxCombo,
      bossDefeated: guardianPurified, // keep field name for backend compat
      treasuresFound,
      finalHp: energy
    });
  }

  function skip() {
    soundManager.stopBGM();
    onComplete({ passed: true, totalQuestions: 0, correctAnswers: 0, accuracy: 0, maxCombo: 0, bossDefeated: false, treasuresFound: 0, finalHp: 100 });
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

  // Scene component result handler
  async function handleSceneResult(result: AnswerResult) {
    if (!result) {
      errorMsg = '场景提交失败';
      phase = 'error';
      return;
    }

    submitted = true;
    lastResult = result;
    results[answeredCount] = result.isCorrect;

    triggerPurifyAnimation(result.isCorrect, result.isLastQuestion);

    if (result.isCorrect) {
      combo++;
      maxCombo = Math.max(maxCombo, combo);
      if (combo >= 3) spiritMood = 'excited';
      energy = Math.min(100, energy + 10);
      if (combo >= 2 && combo % 2 === 0) {
        treasuresFound++;
        soundManager.playTreasure?.();
      }
      if (result.isLastQuestion && result.isCorrect) {
        guardianPurified = true;
        soundManager.playBossDefeated?.();
      }
    } else {
      combo = 0;
      // No HP loss — purification has no death
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
  }

  // Is this a scene-type question?
  const isSceneQuestion = $derived(
    question?.questionType === 'SCENE_DRAG' || question?.questionType === 'SCENE_TAP' ||
    question?.questionType === 'SCENE_MATCH' || question?.questionType === 'SCENE_WHACK_MOLE' ||
    question?.questionType === 'SCENE_SHAPE_PUZZLE' || question?.questionType === 'SCENE_CLOCK' ||
    question?.questionType === 'SCENE_SHOP' || question?.questionType === 'SCENE_PINYIN' ||
    question?.questionType === 'SCENE_CHAR_BUILD'
  );

  const showSubmitBtn = $derived(
    !submitted && !isSceneQuestion &&
    question?.questionType !== 'POEM_SEQUENCE' && question?.questionType !== 'VOCAB_MATCH'
  );
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
    <!-- Mini header: HP + Combo + Progress dots -->
    <div class="flex items-center justify-between px-4 pt-3 pb-1">
      <EnergyBar {energy} maxEnergy={100} />
      <div class="flex gap-1.5">
        {#each Array(totalQuestions) as _, i}
          <div class="w-2 h-2 rounded-full transition-all duration-300"
               class:bg-indigo-400={i === answeredCount}
               class:bg-emerald-400={results[i] === true}
               class:bg-red-400={results[i] === false}
               class:bg-gray-200={i > answeredCount || (i === answeredCount && results[i] === null)}>
          </div>
        {/each}
      </div>
      <ComboCounter {combo} />
    </div>

    <!-- Battle Scene: pet vs monster (prominent!) -->
    <div class="px-3 pt-2 pb-1">
      <BattleScene
        {subject}
        species={spiritStore.activeSpirit?.species ?? null}
        evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
        mood={spiritMood}
        currentIndex={answeredCount}
        {totalQuestions}
        isBoss={isLastQuestion}
        bossHp={isLastQuestion ? 3 : 1}
        bossMaxHp={isLastQuestion ? 3 : 1}
        {combo}
        state={purifyState}
      />
    </div>

    <!-- Question with crossfade transition -->
    {#key question.questionId}
    <div class="px-4 pb-4 question-fade">
      {#if question.questionType === 'SCENE_DRAG'}
        <SceneMathTen question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_TAP'}
        <SceneTap question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_MATCH'}
        <SceneMatch question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_WHACK_MOLE'}
        <SceneWhackMole question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_SHAPE_PUZZLE'}
        <SceneShapePuzzle question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_CLOCK'}
        <SceneClock question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_SHOP'}
        <SceneShop question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_PINYIN'}
        <ScenePinyinBubble question={question} {sessionId} onComplete={handleSceneResult} />
      {:else if question.questionType === 'SCENE_CHAR_BUILD'}
        <SceneCharBuild question={question} {sessionId} onComplete={handleSceneResult} />
      {:else}
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
      {/if}

      {#if showSubmitBtn}
        <button onclick={handleSubmit} disabled={!selectedAnswer}
                class="mt-3 w-full py-2.5 bg-indigo-500 text-white rounded-lg font-semibold hover:bg-indigo-600 disabled:opacity-50 transition text-sm">
          提交答案
        </button>
      {/if}
    </div>
    {/key}
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

<style>
  @keyframes qFadeIn {
    0% { opacity: 0; transform: scale(0.96) translateY(6px); }
    100% { opacity: 1; transform: scale(1) translateY(0); }
  }
  :global(.question-fade) {
    animation: qFadeIn 0.3s ease-out;
  }
</style>
