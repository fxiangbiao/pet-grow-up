<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { startSession, submitAnswer } from '$lib/api/study';
  import { subscribeToSession } from '$lib/api/study-ws';
  import type { QuestionDTO, AnswerResult } from '$lib/api/study';
  import CorrectIndicator from '$lib/components/feedback/CorrectIndicator.svelte';
  import WrongIndicator from '$lib/components/feedback/WrongIndicator.svelte';
  import SessionResult from '$lib/components/study/SessionResult.svelte';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import PoemSequence from '$lib/components/study/PoemSequence.svelte';
  import MathInput from '$lib/components/study/MathInput.svelte';
  import VocabMatch from '$lib/components/study/VocabMatch.svelte';
  import HpBar from '$lib/components/study/HpBar.svelte';
  import ComboCounter from '$lib/components/study/ComboCounter.svelte';
  import AdventurePath from '$lib/components/study/AdventurePath.svelte';
  import BattleScene from '$lib/components/study/BattleScene.svelte';
  import BossSection from '$lib/components/study/BossSection.svelte';
  import BossBattle from '$lib/components/study/BossBattle.svelte';
  import TreasureChest from '$lib/components/study/TreasureChest.svelte';
  import ExploreConfirm from '$lib/components/study/ExploreConfirm.svelte';
  import SceneMathTen from '$lib/components/study/SceneMathTen.svelte';
  import SceneTap from '$lib/components/study/SceneTap.svelte';
  import SceneMatch from '$lib/components/study/SceneMatch.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  const subject = $derived($page.params.subject as string);
  const nodeId = $derived(Number($page.url.searchParams.get('nodeId')));

  // Page states
  let phase = $state<'confirm' | 'playing' | 'result'>('confirm');
  let loading = $state(false);
  let error = $state('');

  // Playing state
  let question = $state<QuestionDTO | null>(null);
  let sessionId = $state<number>(0);
  let selectedAnswer = $state('');
  let submitted = $state(false);
  let lastResult = $state<AnswerResult | null>(null);
  let totalQuestions = $state(0);
  let answeredCount = $state(0);
  let questionStartTime = $state<number>(0);

  // Adventure state
  let hp = $state(5);
  let combo = $state(0);
  let maxCombo = $state(0);
  let bossDefeated = $state(false);
  let bossThemePlayed = $state(false);
  // Boss battle state (BossBattle component integration)
  let showBossBattle = $state(false);
  let bossAnswerTimeMs = $state(0);
  let bossBattleResolved = $state(false);
  let treasuresFound = $state(0);
  let results = $state<Array<boolean | null>>([]);
  let adventureEnded = $state(false);
  // Battle scene state
  let battleState = $state<'idle' | 'player_attack' | 'enemy_attack' | 'enemy_defeated'>('idle');

  // Treasure chest overlay state
  let showTreasureChest = $state(false);
  let treasureTier = $state<'small' | 'big'>('small');
  let treasureEnergy = $state(0);

  // Play boss theme when approaching the final question and activate BossBattle
  $effect(() => {
    if (isLastQuestion && phase === 'playing' && !bossThemePlayed) {
      soundManager.playBossTheme();
      bossThemePlayed = true;
      // Activate boss battle after the pre-boss preview
      setTimeout(() => {
        showBossBattle = true;
      }, 1500); // brief delay to show BossSection preview first
    }
  });

  // Spirit mood derived from adventure state
  const spiritMood = $derived(
    adventureEnded ? 'hurt' :
    lastResult === null ? 'idle' :
    lastResult.isCorrect ? (combo >= 2 ? 'excited' : 'happy') :
    'hurt'
  );

  const subjectData: Record<string, { name: string; emoji: string }> = {
    chinese: { name: '诗词大陆', emoji: '📜' },
    math: { name: '智慧王国', emoji: '🔢' },
    english: { name: '魔法学院', emoji: '🔤' }
  };

  const subjectTheme = $derived.by(() => {
    const themes: Record<string, { border: string; bg: string; accent: string; bar: string; bgClass: string; decoClass: string }> = {
      chinese: { border: 'border-amber-300', bg: 'bg-amber-50', accent: 'text-amber-700', bar: 'bg-amber-500', bgClass: 'adventure-bg-chinese', decoClass: 'bg-deco-chinese' },
      math: { border: 'border-blue-300', bg: 'bg-blue-50', accent: 'text-blue-700', bar: 'bg-blue-500', bgClass: 'adventure-bg-math', decoClass: 'bg-deco-math' },
      english: { border: 'border-purple-300', bg: 'bg-purple-50', accent: 'text-purple-700', bar: 'bg-purple-500', bgClass: 'adventure-bg-english', decoClass: 'bg-deco-english' }
    };
    return themes[subject] || themes.chinese;
  });

  function resetAdventure() {
    hp = 5;
    combo = 0;
    maxCombo = 0;
    bossDefeated = false;
    bossThemePlayed = false;
    showBossBattle = false;
    bossAnswerTimeMs = 0;
    bossBattleResolved = false;
    battleState = 'idle';
    treasuresFound = 0;
    results = [];
    adventureEnded = false;
    showTreasureChest = false;
    treasureTier = 'small';
    treasureEnergy = 0;
  }

  async function handleStart() {
    loading = true;
    error = '';
    resetAdventure();
    // Ensure spirits are loaded for BattleScene pet display
    spiritStore.refresh(0);
    try {
      const result = await startSession({ subject, sessionType: 'DAILY', difficultyLevel: 1, knowledgeNodeId: nodeId });
      sessionId = result.sessionId;
      question = result;
      totalQuestions = result.totalQuestions ?? 5;
      answeredCount = result.answeredCount ?? 0;
      results = Array(totalQuestions).fill(null);
      phase = 'playing';
      questionStartTime = Date.now();
      soundManager.playBGM(subject);
    } catch (e: any) {
      error = e.message || '启动失败';
    } finally {
      loading = false;
    }
  }

  function selectAnswer(answer: string) {
    if (submitted) return;
    selectedAnswer = answer;
  }

  async function handleSubmit() {
    if (!selectedAnswer || submitted || !question || adventureEnded) return;
    submitted = true;
    try {
      const result = await submitAnswer({ sessionId, questionId: question.questionId, answer: selectedAnswer, timeSpent: Math.max(0, Math.floor((Date.now() - questionStartTime) / 1000)) });
      lastResult = result;
      results[answeredCount] = result.isCorrect;

      // Trigger battle animation
      if (result.isCorrect) {
        battleState = 'player_attack';
        setTimeout(() => { battleState = 'idle'; }, 600);
      } else {
        battleState = 'enemy_attack';
        setTimeout(() => { battleState = 'idle'; }, 600);
      }

      if (result.isCorrect) {
        combo++;
        maxCombo = Math.max(maxCombo, combo);

        // Boss battle: capture answer time for damage calc, delegate to BossBattle
        if (result.isLastQuestion) {
          bossAnswerTimeMs = Math.max(0, Math.floor(Date.now() - questionStartTime));
          // BossBattle handles bossDefeated, HP, and transitions via callbacks
          // DO NOT set bossDefeated or transition to result here
        } else {
          // Treasure chest for non-boss questions
          if (combo >= 2 && combo % 2 === 0) {
            treasuresFound++;
            treasureTier = combo >= 4 ? 'big' : 'small';
            treasureEnergy = treasureTier === 'big' ? 10 : 5;
            if (treasureTier === 'big' && hp < 5) {
              hp = Math.min(5, hp + 1);
            }
            showTreasureChest = true;
          }
        }
      } else {
        combo = 0;
        if (result.isLastQuestion) {
          // Boss question wrong: BossBattle handles attack animation via callback
          bossAnswerTimeMs = Math.max(0, Math.floor(Date.now() - questionStartTime));
          hp -= 2;
        } else {
          hp -= 1;
        }
        if (hp <= 0) {
          adventureEnded = true;
          setTimeout(() => { phase = 'result'; }, 2000);
          return;
        }
      }

      if (result.isSessionComplete) {
        // For boss battle, BossBattle callbacks handle the transition
        if (!result.isLastQuestion || bossBattleResolved || adventureEnded) {
          setTimeout(() => { phase = 'result'; }, 2000);
        } else {
          // Last question boss battle still active — wait for callback
          // Safety fallback: force result after 10 seconds
          setTimeout(() => {
            if (phase === 'playing') {
              bossBattleResolved = true;
              phase = 'result';
            }
          }, 10000);
        }
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
      error = e.message;
      submitted = false;
    }
  }

  let parsedOptions = $derived.by(() => {
    const opts = question?.options;
    if (!opts) return [];
    // Already an array (MySQL JSON column may be auto-deserialized by JDBC driver)
    if (Array.isArray(opts)) return opts as Array<{ key: string; text: string }>;
    // JSON string (standard case)
    if (typeof opts === 'string') {
      try {
        const parsed = JSON.parse(opts);
        if (Array.isArray(parsed)) return parsed as Array<{ key: string; text: string }>;
      } catch { /* fall through to empty */ }
    }
    // Object with numeric keys or other format — try to convert
    if (typeof opts === 'object' && opts !== null) {
      try {
        const arr = Object.entries(opts).map(([k, v]) => ({ key: k, text: String(v) }));
        if (arr.length > 0) return arr;
      } catch { /* empty */ }
    }
    console.warn('[explore] Cannot parse options:', typeof opts, opts);
    return [];
  });

  let parsedVocabOptions = $derived.by(() => {
    if (!question?.options || question.questionType !== 'VOCAB_MATCH') return null;
    const opts = question.options;
    try {
      // Already an object (MySQL JSON column auto-deserialized)
      if (typeof opts === 'object' && opts !== null && !Array.isArray(opts)) {
        const o = opts as any;
        if (o.left && o.right) return o as { left: Array<{ id: string; text: string }>; right: Array<{ id: string; text: string }> };
      }
      // JSON string
      if (typeof opts === 'string') {
        const parsed = JSON.parse(opts);
        if (parsed && parsed.left && parsed.right) return parsed as { left: Array<{ id: string; text: string }>; right: Array<{ id: string; text: string }> };
      }
    } catch { /* fall through */ }
    console.warn('[explore] Cannot parse vocab options:', typeof question.options, question.options);
    return null;
  });

  let parsedPoemLines = $derived.by(() => {
    if (!question?.options || question.questionType !== 'POEM_SEQUENCE') return [];
    const opts = question.options;
    try {
      // Already an array (MySQL JSON column auto-deserialized)
      if (Array.isArray(opts)) return opts as string[];
      // JSON string
      if (typeof opts === 'string') {
        const parsed = JSON.parse(opts);
        if (Array.isArray(parsed)) return parsed as string[];
      }
    } catch { /* fall through */ }
    console.warn('[explore] Cannot parse poem lines:', typeof question.options, question.options);
    return [];
  });

  function onNewTypeAnswer(answer: string) {
    selectedAnswer = answer;
    handleSubmit();
  }

  // Scene component result handler — processes AnswerResult from SceneMathTen etc.
  async function handleSceneResult(result: AnswerResult) {
    if (!result) {
      console.error('handleSceneResult: null result, forcing result phase');
      phase = 'result';
      return;
    }

    submitted = true;
    lastResult = result;
    results[answeredCount] = result.isCorrect;

    // Trigger battle animation
    if (result.isCorrect) {
      battleState = 'player_attack';
      setTimeout(() => { battleState = 'idle'; }, 800);
    } else {
      battleState = 'enemy_attack';
      setTimeout(() => { battleState = 'idle'; }, 800);
    }

    if (result.isCorrect) {
      combo++;
      maxCombo = Math.max(maxCombo, combo);

      if (result.isLastQuestion) {
        bossAnswerTimeMs = Math.max(0, Math.floor(Date.now() - questionStartTime));
      } else {
        if (combo >= 2 && combo % 2 === 0) {
          treasuresFound++;
          treasureTier = combo >= 4 ? 'big' : 'small';
          treasureEnergy = treasureTier === 'big' ? 10 : 5;
          if (treasureTier === 'big' && hp < 5) {
            hp = Math.min(5, hp + 1);
          }
          showTreasureChest = true;
        }
      }
    } else {
      combo = 0;
      if (result.isLastQuestion) {
        bossAnswerTimeMs = Math.max(0, Math.floor(Date.now() - questionStartTime));
        hp -= 2;
      } else {
        hp -= 1;
      }
      if (hp <= 0) {
        adventureEnded = true;
        setTimeout(() => { phase = 'result'; }, 2000);
        return;
      }
    }

    if (result.isSessionComplete) {
      if (!result.isLastQuestion || bossBattleResolved || adventureEnded) {
        setTimeout(() => { phase = 'result'; }, 2000);
      } else {
        // Last question boss battle still active — wait for callback
        // Safety fallback: force result after 10 seconds
        setTimeout(() => {
          if (phase === 'playing') {
            bossBattleResolved = true;
            phase = 'result';
          }
        }, 10000);
      }
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
    } else {
      // Safety: no next question but session not complete — force advance
      console.error('handleSceneResult: no nextQuestion and session not complete, forcing result');
      setTimeout(() => { phase = 'result'; }, 2000);
    }
  }

  const isLastQuestion = $derived(answeredCount >= totalQuestions - 1);

</script>

<svelte:head>
  <title>探险 - Pet Grow Up</title>
</svelte:head>

<div class="min-h-screen {subjectTheme.bgClass} {phase === 'playing' ? 'pb-8' : ''}">
  <!-- Background decorations -->
  {#if phase === 'playing'}
    {#if subject === 'chinese'}
      <div class="bg-deco-chinese">
        <span>诗</span><span>词</span><span>文</span><span>韵</span><span>书</span><span>墨</span>
      </div>
    {:else if subject === 'math'}
      <div class="bg-deco-math"></div>
    {:else if subject === 'english'}
      <div class="bg-deco-english">
        <span>A</span><span>B</span><span>C</span><span>D</span><span>E</span><span>F</span><span>G</span><span>H</span>
      </div>
    {/if}
  {/if}

  <div class="max-w-2xl mx-auto animate-slide-up relative z-10 px-4">
  {#if phase === 'confirm'}
    <ExploreConfirm
      {subject}
      subjectName={subjectData[subject]?.name || subject}
      subjectEmoji={subjectData[subject]?.emoji || '🌍'}
      species={spiritStore.activeSpirit?.species ?? null}
      evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
      mood={spiritMood}
      {loading}
      {error}
      onStart={handleStart}
    />

  {:else if phase === 'playing' && question}
    <div class="bg-white/85 backdrop-blur-sm rounded-2xl shadow-lg p-4 border-2 {subjectTheme.border}">
      <!-- Top bar: HP + Combo -->
      <div class="flex items-center justify-between mb-2">
        <HpBar {hp} maxHp={5} />
        <ComboCounter {combo} />
      </div>

      <!-- Battle scene: spirit vs enemy visual combat view -->
      <div class="mb-3">
        <BattleScene
          {subject}
          species={spiritStore.activeSpirit?.species ?? null}
          evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
          mood={spiritMood}
          currentIndex={answeredCount}
          {totalQuestions}
          isBoss={isLastQuestion}
          bossHp={bossDefeated ? 0 : 100}
          bossMaxHp={100}
          {combo}
          state={battleState}
        />
      </div>

      <!-- Boss battle: interactive phased boss encounter -->
      {#if showBossBattle}
        <BossBattle
          visible={true}
          {subject}
          {combo}
          playerHp={hp}
          answerResult={lastResult}
          answerTimeMs={bossAnswerTimeMs}
          sceneMode={['SCENE_DRAG', 'SCENE_TAP', 'SCENE_MATCH'].includes(question.questionType)}
          onBossDefeated={() => {
            bossDefeated = true;
            bossBattleResolved = true;
            battleState = 'enemy_defeated';
            soundManager.playBossDefeated();
            setTimeout(() => { phase = 'result'; }, 2500);
          }}
          onBossAttackPlayer={() => {
            battleState = 'enemy_attack';
            setTimeout(() => { battleState = 'idle'; }, 600);
            bossBattleResolved = true;
            // Boss attacked — encounter is over regardless of remaining HP.
            // Always transition to result (session complete after boss question).
            if (hp <= 0) {
              adventureEnded = true;
            }
            setTimeout(() => { phase = 'result'; }, 2500);
          }}
          onBossEscaped={() => {
            bossBattleResolved = true;
            soundManager.playComplete();
            setTimeout(() => { phase = 'result'; }, 2000);
          }}
        />
      {/if}

      <!-- Compact progress dots below scene -->
      <div class="mb-2">
        <AdventurePath
          totalQuestions={totalQuestions}
          currentIndex={answeredCount}
          results={results}
          species={spiritStore.activeSpirit?.species ?? null}
          evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
          mood={spiritMood}
          subjectTheme={subject}
        />
      </div>

      <!-- Question area -->
      {#key question.questionId}
      {#if question.questionType === 'SCENE_DRAG'}
        <SceneMathTen question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
      {:else if question.questionType === 'SCENE_TAP'}
        <SceneTap question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
      {:else if question.questionType === 'SCENE_MATCH'}
        <SceneMatch question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
      {:else}
        <div class="mb-3">
          <h2 class="text-base font-medium text-gray-800 mb-4">{question.questionText}</h2>

          {#if question.questionType === 'MULTIPLE_CHOICE'}
            {#if parsedOptions.length > 0}
              <div class="space-y-2">
                {#each parsedOptions as opt}
                  <button onclick={() => selectAnswer(opt.key)} disabled={submitted}
                    class={['w-full text-left px-4 py-3 rounded-xl border-2 transition text-sm',
                      selectedAnswer === opt.key ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300'
                    ].join(' ')}>
                    <span class="font-medium">{opt.key}.</span> {opt.text}
                  </button>
                {/each}
              </div>
            {:else}
              <!-- Fallback: options failed to parse — show text input -->
              <p class="text-xs text-amber-600 mb-2">⚠️ 选项加载异常，请直接输入答案</p>
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案（如：5）..."
                     class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else if question.questionType === 'FILL_BLANK'}
            <input type="text" bind:value={selectedAnswer} disabled={submitted}
                   placeholder="输入你的答案..."
                   class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-indigo-500 outline-none transition" />
          {:else if question.questionType === 'TRUE_FALSE'}
            <div class="grid grid-cols-2 gap-4">
              <button onclick={() => selectAnswer('true')} disabled={submitted}
                class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                  selectedAnswer === 'true' ? 'border-green-500 bg-green-50 text-green-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>
                ✓ 正确
              </button>
              <button onclick={() => selectAnswer('false')} disabled={submitted}
                class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                  selectedAnswer === 'false' ? 'border-red-500 bg-red-50 text-red-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>
                ✗ 错误
              </button>
            </div>
          {:else if question.questionType === 'POEM_SEQUENCE'}
            {#if parsedPoemLines.length > 0}
              <PoemSequence options={parsedPoemLines} disabled={submitted} onSelect={onNewTypeAnswer} />
            {:else}
              <p class="text-xs text-amber-600 mb-2">⚠️ 诗句加载异常，请直接输入答案</p>
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案..."
                     class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else if question.questionType === 'MATH_INPUT'}
            <MathInput disabled={submitted} onSelect={(v) => { selectedAnswer = v; }} />
          {:else if question.questionType === 'VOCAB_MATCH'}
            {#if parsedVocabOptions}
              <VocabMatch options={parsedVocabOptions} disabled={submitted} onSelect={onNewTypeAnswer} />
            {:else}
              <p class="text-xs text-amber-600 mb-2">⚠️ 配对数据加载异常，请直接输入答案</p>
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案..."
                     class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else}
            <!-- Fallback for unrecognized question types: text input -->
            <input type="text" bind:value={selectedAnswer} disabled={submitted}
                   placeholder="输入你的答案..."
                   class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-indigo-500 outline-none transition" />
          {/if}

          {#if !submitted && question.questionType !== 'POEM_SEQUENCE' && question.questionType !== 'VOCAB_MATCH'}
            <button onclick={handleSubmit} disabled={!selectedAnswer}
                    class="mt-4 w-full py-3.5 bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 text-white text-lg font-black rounded-xl
                      hover:from-amber-300 hover:via-orange-300 hover:to-red-400
                      disabled:from-gray-300 disabled:via-gray-300 disabled:to-gray-300 disabled:text-gray-400
                      transition-all active:scale-95 shadow-lg">
              ⚔️ 攻击！
            </button>
          {:else if !submitted && question.questionType === 'POEM_SEQUENCE' && parsedPoemLines.length === 0}
            <!-- Fallback submit button when poem parsing failed -->
            <button onclick={handleSubmit} disabled={!selectedAnswer}
                    class="mt-4 w-full py-3.5 bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 text-white text-lg font-black rounded-xl
                      hover:from-amber-300 hover:via-orange-300 hover:to-red-400
                      disabled:from-gray-300 disabled:via-gray-300 disabled:to-gray-300 disabled:text-gray-400
                      transition-all active:scale-95 shadow-lg">
              ⚔️ 攻击！
            </button>
          {:else if !submitted && question.questionType === 'VOCAB_MATCH' && !parsedVocabOptions}
            <!-- Fallback submit button when vocab parsing failed -->
            <button onclick={handleSubmit} disabled={!selectedAnswer}
                    class="mt-4 w-full py-3.5 bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 text-white text-lg font-black rounded-xl
                      hover:from-amber-300 hover:via-orange-300 hover:to-red-400
                      disabled:from-gray-300 disabled:via-gray-300 disabled:to-gray-300 disabled:text-gray-400
                      transition-all active:scale-95 shadow-lg">
              ⚔️ 攻击！
            </button>
          {/if}
        </div>
      {/if}
      {/key}
    </div>

    <!-- Feedback -->
    {#if lastResult}
      <div class="mt-3">
        {#if lastResult.isCorrect}
          <CorrectIndicator {combo} isBoss={lastResult.isLastQuestion} />
        {:else}
          <WrongIndicator correctAnswer={lastResult.correctAnswer} explanation={lastResult.explanation} isBoss={lastResult.isLastQuestion} />
        {/if}
      </div>
    {/if}

    <!-- Treasure chest overlay -->
    <TreasureChest show={showTreasureChest} tier={treasureTier} energyBonus={treasureEnergy} {subject}
      onCollected={() => { showTreasureChest = false; }} />

  {:else if phase === 'result'}
    <SessionResult
      {subject}
      {sessionId}
      {maxCombo}
      {bossDefeated}
      {treasuresFound}
      startHp={5}
      finalHp={Math.max(hp, 0)}
      onclose={() => goto(`/app/study/${subject}`)}
    />
  {/if}

  {#if error}
    <div class="mt-3 bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">{error}</div>
  {/if}
  </div>
</div>
