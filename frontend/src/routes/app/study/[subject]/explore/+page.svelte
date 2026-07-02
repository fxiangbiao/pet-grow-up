<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onDestroy } from 'svelte';
  import { startSession, submitAnswer } from '$lib/api/study';
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
  import AdventureMap from '$lib/components/study/AdventureMap.svelte';
  import EnemySprite from '$lib/components/study/EnemySprite.svelte';
  import BattleScene from '$lib/components/study/BattleScene.svelte';
  import BossBattle from '$lib/components/study/BossBattle.svelte';
  import TreasureChest from '$lib/components/study/TreasureChest.svelte';
  import ExploreConfirm from '$lib/components/study/ExploreConfirm.svelte';
  import SceneMathTen from '$lib/components/study/SceneMathTen.svelte';
  import SceneTap from '$lib/components/study/SceneTap.svelte';
  import SceneMatch from '$lib/components/study/SceneMatch.svelte';
  import SceneWhackMole from '$lib/components/study/SceneWhackMole.svelte';
  import SceneShapePuzzle from '$lib/components/study/SceneShapePuzzle.svelte';
  import SceneClock from '$lib/components/study/SceneClock.svelte';
  import SceneShop from '$lib/components/study/SceneShop.svelte';
  import ScenePinyinBubble from '$lib/components/study/ScenePinyinBubble.svelte';
  import SceneCharBuild from '$lib/components/study/SceneCharBuild.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  const subject = $derived($page.params.subject as string);
  const nodeId = $derived(Number($page.url.searchParams.get('nodeId')));

  // ── Page phases ──
  let phase = $state<'confirm' | 'playing' | 'result'>('confirm');
  let loading = $state(false);
  let error = $state('');

  // ── Question state ──
  let question = $state<QuestionDTO | null>(null);
  let sessionId = $state<number>(0);
  let selectedAnswer = $state('');
  let submitted = $state(false);
  let lastResult = $state<AnswerResult | null>(null);
  let totalQuestions = $state(0);
  let answeredCount = $state(0);
  let questionStartTime = $state<number>(0);

  // ── Adventure state ──
  let hp = $state(5);
  let combo = $state(0);
  let maxCombo = $state(0);
  let bossDefeated = $state(false);
  let bossThemePlayed = $state(false);
  let treasuresFound = $state(0);
  let results = $state<Array<boolean | null>>([]);
  let adventureEnded = $state(false);

  // ── Monster node HP tracking ──
  let nodeHps = $state<number[]>([]);
  let nodeMaxHps = $state<number[]>([]);
  const MONSTER_HP_MINION = 1;   // minions die in 1 hit
  const MONSTER_HP_BOSS = 3;     // boss takes 3 hits

  // ── Boss battle state ──
  let showBossBattle = $state(false);
  let bossAnswerTimeMs = $state(0);
  let bossBattleResolved = $state(false);

  // ── Battle scene animation ──
  let battleState = $state<'idle' | 'player_attack' | 'enemy_attack' | 'enemy_defeated'>('idle');

  // ── Map animation ──
  let animatingToNode = $state(-1);

  // ── Treasure chest ──
  let showTreasureChest = $state(false);
  let treasureTier = $state<'small' | 'big'>('small');
  let treasureEnergy = $state(0);

  // ── Derived ──
  const isLastQuestion = $derived(answeredCount >= totalQuestions - 1);
  const currentMonsterMaxHp = $derived(nodeMaxHps[answeredCount] ?? 1);
  const currentMonsterHp = $derived(nodeHps[answeredCount] ?? 1);
  const monsterDefeated = $derived(currentMonsterHp <= 0);

  const spiritMood = $derived(
    adventureEnded ? 'hurt'
    : lastResult === null ? 'idle'
    : lastResult.isCorrect ? (combo >= 2 ? 'excited' : 'happy')
    : 'hurt'
  );

  const subjectData: Record<string, { name: string; emoji: string }> = {
    chinese: { name: '诗词大陆', emoji: '📜' },
    math: { name: '智慧王国', emoji: '🔢' },
    english: { name: '魔法学院', emoji: '🔤' },
  };

  const subjectTheme = $derived.by(() => {
    const themes: Record<string, { border: string; bg: string; accent: string; bar: string }> = {
      chinese: { border: 'border-amber-300', bg: 'bg-amber-50', accent: 'text-amber-700', bar: 'bg-amber-500' },
      math: { border: 'border-blue-300', bg: 'bg-blue-50', accent: 'text-blue-700', bar: 'bg-blue-500' },
      english: { border: 'border-purple-300', bg: 'bg-purple-50', accent: 'text-purple-700', bar: 'bg-purple-500' },
    };
    return themes[subject] || themes.chinese;
  });

  const sceneTypes = ['SCENE_DRAG', 'SCENE_TAP', 'SCENE_MATCH', 'SCENE_WHACK_MOLE',
    'SCENE_SHAPE_PUZZLE', 'SCENE_CLOCK', 'SCENE_SHOP', 'SCENE_PINYIN', 'SCENE_CHAR_BUILD'];

  // ── Boss theme activation ──
  $effect(() => {
    if (isLastQuestion && phase === 'playing' && !bossThemePlayed) {
      soundManager.playBossTheme();
      bossThemePlayed = true;
      setTimeout(() => { showBossBattle = true; }, 1500);
    }
  });

  // ── BGM lifecycle ──
  onDestroy(() => { soundManager.stopBGM(); });
  $effect(() => {
    if (phase === 'result') { soundManager.stopBGM(); }
  });

  // ── Init node HP ──
  function initNodeHps(total: number) {
    const hps: number[] = [];
    const maxHps: number[] = [];
    for (let i = 0; i < total; i++) {
      if (i === total - 1) {
        maxHps.push(MONSTER_HP_BOSS);
        hps.push(MONSTER_HP_BOSS);
      } else {
        maxHps.push(MONSTER_HP_MINION);
        hps.push(MONSTER_HP_MINION);
      }
    }
    nodeHps = hps;
    nodeMaxHps = maxHps;
  }

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
    animatingToNode = -1;
    nodeHps = [];
    nodeMaxHps = [];
  }

  async function handleStart() {
    loading = true;
    error = '';
    resetAdventure();
    spiritStore.refresh(0);
    try {
      const result = await startSession({ subject, sessionType: 'DAILY', difficultyLevel: 1, knowledgeNodeId: nodeId });
      sessionId = result.sessionId;
      question = result;
      totalQuestions = result.totalQuestions ?? 5;
      answeredCount = result.answeredCount ?? 0;
      results = Array(totalQuestions).fill(null);
      initNodeHps(totalQuestions);
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

  // ── Damage current monster ──
  function damageMonster(amount: number) {
    const newHps = [...nodeHps];
    newHps[answeredCount] = Math.max(0, newHps[answeredCount] - amount);
    nodeHps = newHps;
  }

  // ── Main submit ──
  async function handleSubmit() {
    if (!selectedAnswer || submitted || !question || adventureEnded) return;
    submitted = true;
    try {
      const result = await submitAnswer({
        sessionId, questionId: question.questionId, answer: selectedAnswer,
        timeSpent: Math.max(0, Math.floor((Date.now() - questionStartTime) / 1000)),
      });
      processResult(result);
    } catch (e: any) {
      error = e.message;
      submitted = false;
    }
  }

  // ── Scene result ──
  async function handleSceneResult(result: AnswerResult) {
    if (!result) { phase = 'result'; return; }
    submitted = true;
    processResult(result);
  }

  // ── Unified result processing ──
  function processResult(result: AnswerResult) {
    lastResult = result;
    results[answeredCount] = result.isCorrect;

    if (result.isCorrect) {
      combo++;
      maxCombo = Math.max(maxCombo, combo);

      // ⚔️ Pet attacks monster!
      battleState = 'player_attack';
      setTimeout(() => { battleState = 'idle'; }, 600);

      // Damage the current monster
      const damage = isLastQuestion && combo >= 3 ? 2 : 1; // crit on boss with combo
      damageMonster(damage);

      // Boss battle: capture answer time
      if (result.isLastQuestion) {
        bossAnswerTimeMs = Math.max(0, Math.floor(Date.now() - questionStartTime));
      } else {
        // Treasure chest
        if (combo >= 2 && combo % 2 === 0) {
          treasuresFound++;
          treasureTier = combo >= 4 ? 'big' : 'small';
          treasureEnergy = treasureTier === 'big' ? 10 : 5;
          if (treasureTier === 'big' && hp < 5) hp = Math.min(5, hp + 1);
          showTreasureChest = true;
        }
      }
    } else {
      combo = 0;

      // 👾 Monster counter-attacks!
      battleState = 'enemy_attack';
      setTimeout(() => { battleState = 'idle'; }, 600);

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

    // Session complete?
    if (result.isSessionComplete) {
      if (!result.isLastQuestion || bossBattleResolved || adventureEnded) {
        setTimeout(() => { phase = 'result'; }, 2000);
      } else {
        setTimeout(() => {
          if (phase === 'playing') { bossBattleResolved = true; phase = 'result'; }
        }, 10000);
      }
    } else if (result.nextQuestion) {
      const nextQ = result.nextQuestion;
      const nextIdx = answeredCount + 1;
      // Animate token to next node
      animatingToNode = nextIdx;
      setTimeout(() => {
        question = nextQ;
        answeredCount = nextQ.answeredCount ?? nextIdx;
        submitted = false;
        selectedAnswer = '';
        lastResult = null;
        questionStartTime = Date.now();
        animatingToNode = -1;
      }, 800);
    }
  }

  function onNewTypeAnswer(answer: string) {
    selectedAnswer = answer;
    handleSubmit();
  }

  // ── Options parsing ──
  let parsedOptions = $derived.by(() => {
    const opts = question?.options;
    if (!opts) return [];
    if (Array.isArray(opts)) return opts as Array<{ key: string; text: string }>;
    if (typeof opts === 'string') {
      try { const p = JSON.parse(opts); if (Array.isArray(p)) return p as Array<{ key: string; text: string }>; } catch {}
    }
    if (typeof opts === 'object' && opts !== null) {
      try { const arr = Object.entries(opts).map(([k, v]) => ({ key: k, text: String(v) })); if (arr.length > 0) return arr; } catch {}
    }
    return [];
  });

  let parsedVocabOptions = $derived.by(() => {
    if (!question?.options || question.questionType !== 'VOCAB_MATCH') return null;
    const opts = question.options;
    try {
      if (typeof opts === 'object' && opts !== null && !Array.isArray(opts)) {
        const o = opts as any; if (o.left && o.right) return o;
      }
      if (typeof opts === 'string') { const p = JSON.parse(opts); if (p?.left && p?.right) return p; }
    } catch {}
    return null;
  });

  let parsedPoemLines = $derived.by(() => {
    if (!question?.options || question.questionType !== 'POEM_SEQUENCE') return [];
    const opts = question.options;
    try {
      if (Array.isArray(opts)) return opts as string[];
      if (typeof opts === 'string') { const p = JSON.parse(opts); if (Array.isArray(p)) return p as string[]; }
    } catch {}
    return [];
  });
</script>

<svelte:head>
  <title>探险 - Pet Grow Up</title>
</svelte:head>

<div class="min-h-screen {subject === 'chinese' ? 'adventure-bg-chinese' : subject === 'math' ? 'adventure-bg-math' : 'adventure-bg-english'} {phase === 'playing' ? 'pb-8' : ''}">
  <div class="max-w-2xl mx-auto animate-slide-up relative z-10 px-4">

  <!-- ═══ CONFIRM ═══ -->
  {#if phase === 'confirm'}
    <ExploreConfirm
      {subject}
      subjectName={subjectData[subject]?.name || subject}
      subjectEmoji={subjectData[subject]?.emoji || '🌍'}
      species={spiritStore.activeSpirit?.species ?? null}
      evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
      mood={spiritMood}
      {loading} {error}
      onStart={handleStart}
    />

  <!-- ═══ PLAYING ═══ -->
  {:else if phase === 'playing' && question}
    <div class="bg-white/85 backdrop-blur-sm rounded-2xl shadow-lg p-4 border-2 {subjectTheme.border}">

      <!-- ═══ COSMIC ADVENTURE MAP ═══ -->
      <div class="mb-3">
        <AdventureMap
          {subject}
          nodeCount={totalQuestions}
          currentNodeIndex={answeredCount}
          nodeResults={results}
          {nodeHps} {nodeMaxHps}
          species={spiritStore.activeSpirit?.species ?? null}
          evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
          {animatingToNode}
          {battleState}
        />
      </div>

      <!-- ═══ STATS BAR: HP + Combo ═══ -->
      <div class="flex items-center justify-between mb-2">
        <HpBar {hp} maxHp={5} />
        <ComboCounter {combo} />
      </div>

      <!-- ═══ BATTLE SCENE: Pet vs Monster ═══ -->
      <div class="mb-3">
        <BattleScene
          {subject}
          species={spiritStore.activeSpirit?.species ?? null}
          evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
          mood={spiritMood}
          currentIndex={answeredCount}
          {totalQuestions}
          isBoss={isLastQuestion}
          bossHp={isLastQuestion ? currentMonsterHp : 0}
          bossMaxHp={isLastQuestion ? currentMonsterMaxHp : 1}
          {combo}
          state={battleState}
        />
      </div>

      <!-- ═══ BOSS BATTLE ═══ -->
      {#if showBossBattle}
        <BossBattle
          visible={true}
          {subject}
          {combo}
          playerHp={hp}
          answerResult={lastResult}
          answerTimeMs={bossAnswerTimeMs}
          sceneMode={question ? sceneTypes.includes(question.questionType) : false}
          onBossDefeated={() => {
            bossDefeated = true;
            bossBattleResolved = true;
            battleState = 'enemy_defeated';
            damageMonster(999); // KO the boss
            soundManager.playBossDefeated();
            setTimeout(() => { phase = 'result'; }, 2500);
          }}
          onBossAttackPlayer={() => {
            battleState = 'enemy_attack';
            setTimeout(() => { battleState = 'idle'; }, 600);
            bossBattleResolved = true;
            if (hp <= 0) adventureEnded = true;
            setTimeout(() => { phase = 'result'; }, 2500);
          }}
          onBossEscaped={() => {
            bossBattleResolved = true;
            soundManager.playComplete();
            setTimeout(() => { phase = 'result'; }, 2000);
          }}
        />
      {/if}

      <!-- ═══ QUESTION AREA ═══ -->
      <div class="question-fade" style="animation: qFadeIn 0.3s ease-out;">
      {#key question.questionId}
      {#if sceneTypes.includes(question.questionType)}
        {#if question.questionType === 'SCENE_DRAG'}
          <SceneMathTen question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_TAP'}
          <SceneTap question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_MATCH'}
          <SceneMatch question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_WHACK_MOLE'}
          <SceneWhackMole question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_SHAPE_PUZZLE'}
          <SceneShapePuzzle question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_CLOCK'}
          <SceneClock question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_SHOP'}
          <SceneShop question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_PINYIN'}
          <ScenePinyinBubble question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {:else if question.questionType === 'SCENE_CHAR_BUILD'}
          <SceneCharBuild question={question} {sessionId} onComplete={(r) => handleSceneResult(r)} />
        {/if}
      {:else}
        <div class="mb-3">
          <h2 class="text-base font-medium text-gray-800 mb-4">{question.questionText}</h2>
          {#if question.questionType === 'MULTIPLE_CHOICE'}
            {#if parsedOptions.length > 0}
              <div class="space-y-2">
                {#each parsedOptions as opt}
                  <button onclick={() => selectAnswer(opt.key)} disabled={submitted}
                    class={['w-full text-left px-4 py-3 rounded-xl border-2 transition text-sm',
                      selectedAnswer === opt.key ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300'].join(' ')}>
                    <span class="font-medium">{opt.key}.</span> {opt.text}
                  </button>
                {/each}
              </div>
            {:else}
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案..." class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else if question.questionType === 'FILL_BLANK'}
            <input type="text" bind:value={selectedAnswer} disabled={submitted}
                   placeholder="输入你的答案..." class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-indigo-500 outline-none transition" />
          {:else if question.questionType === 'TRUE_FALSE'}
            <div class="grid grid-cols-2 gap-4">
              <button onclick={() => selectAnswer('true')} disabled={submitted}
                class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                  selectedAnswer === 'true' ? 'border-green-500 bg-green-50 text-green-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>✓ 正确</button>
              <button onclick={() => selectAnswer('false')} disabled={submitted}
                class={['py-4 rounded-xl border-2 text-center transition text-lg font-medium',
                  selectedAnswer === 'false' ? 'border-red-500 bg-red-50 text-red-700' : 'border-gray-200 hover:border-gray-300'].join(' ')}>✗ 错误</button>
            </div>
          {:else if question.questionType === 'POEM_SEQUENCE'}
            {#if parsedPoemLines.length > 0}
              <PoemSequence options={parsedPoemLines} disabled={submitted} onSelect={onNewTypeAnswer} />
            {:else}
              <p class="text-xs text-amber-600 mb-2">⚠️ 诗句加载异常，请直接输入答案</p>
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案..." class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else if question.questionType === 'MATH_INPUT'}
            <MathInput disabled={submitted} onSelect={(v) => { selectedAnswer = v; }} />
          {:else if question.questionType === 'VOCAB_MATCH'}
            {#if parsedVocabOptions}
              <VocabMatch options={parsedVocabOptions} disabled={submitted} onSelect={onNewTypeAnswer} />
            {:else}
              <p class="text-xs text-amber-600 mb-2">⚠️ 配对数据加载异常，请直接输入答案</p>
              <input type="text" bind:value={selectedAnswer} disabled={submitted}
                     placeholder="输入你的答案..." class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-indigo-500 outline-none transition" />
            {/if}
          {:else}
            <input type="text" bind:value={selectedAnswer} disabled={submitted}
                   placeholder="输入你的答案..." class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-indigo-500 outline-none transition" />
          {/if}

          {#if !submitted && question.questionType !== 'POEM_SEQUENCE' && question.questionType !== 'VOCAB_MATCH' && !sceneTypes.includes(question.questionType)}
            <button onclick={handleSubmit} disabled={!selectedAnswer}
                    class="mt-4 w-full py-3.5 bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 text-white text-lg font-black rounded-xl
                      hover:from-amber-300 hover:via-orange-300 hover:to-red-400
                      disabled:from-gray-300 disabled:text-gray-400 transition-all active:scale-95 shadow-lg">
              ⚔️ 攻击！
            </button>
          {/if}
        </div>
      {/if}
      {/key}
      </div>
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

    <!-- Treasure Chest -->
    <TreasureChest show={showTreasureChest} tier={treasureTier} energyBonus={treasureEnergy} {subject}
      onCollected={() => { showTreasureChest = false; }} />

  <!-- ═══ RESULT ═══ -->
  {:else if phase === 'result'}
    <SessionResult
      {subject} {sessionId} {maxCombo} {bossDefeated} {treasuresFound}
      startHp={5} finalHp={Math.max(hp, 0)}
      onclose={() => goto(`/app/study/${subject}`)}
    />
  {/if}

  {#if error}
    <div class="mt-3 bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">{error}</div>
  {/if}
  </div>
</div>

<style>
  @keyframes qFadeIn {
    0% { opacity: 0; transform: scale(0.96) translateY(6px); }
    100% { opacity: 1; transform: scale(1) translateY(0); }
  }
  :global(.question-fade) { animation: qFadeIn 0.3s ease-out; }
</style>
