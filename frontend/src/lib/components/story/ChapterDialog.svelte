<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';
  import { completeChapter } from '$lib/api/story';
  import type { StudyResult } from '$lib/api/story';
  import { toastStore } from '$lib/stores/toast.svelte';
  import StoryStudyTask from './StoryStudyTask.svelte';
  import { onMount } from 'svelte';

  let {
    chapter: initial,
    onClose
  }: {
    chapter: {
      id: number;
      chapterNumber: number;
      title: string;
      narrative: string;
      npcName: string;
      npcDialogue: string;
      choiceText: string;
      rewardEnergy: number;
    };
    onClose: () => void;
  } = $props();

  let phase = $state<'narrative' | 'dialogue' | 'choice' | 'study' | 'study_result' | 'done'>('narrative');
  let dialogueIndex = $state(0);
  let displayText = $state('');
  let isTyping = $state(false);
  let closing = $state(false);
  let speechSupported = $state(false);
  let studyResult = $state<StudyResult | null>(null);

  const dialogueLines = $derived(initial.npcDialogue ? initial.npcDialogue.split('\n').filter(l => l.trim()) : [initial.npcDialogue]);
  const currentLine = $derived(dialogueLines[dialogueIndex] || '');

  const npcInfo: Record<string, { emoji: string; color: string; bg: string }> = {
    '向导精灵': { emoji: '🧚', color: 'from-indigo-400 to-purple-500', bg: 'bg-indigo-50' },
    '李白': { emoji: '🏮', color: 'from-amber-400 to-orange-500', bg: 'bg-amber-50' },
    '智慧老人': { emoji: '🧙', color: 'from-blue-400 to-cyan-500', bg: 'bg-blue-50' },
    '梅林导师': { emoji: '🔮', color: 'from-purple-400 to-pink-500', bg: 'bg-purple-50' },
    '李清照': { emoji: '🌸', color: 'from-pink-400 to-rose-500', bg: 'bg-pink-50' },
    '毕达哥拉斯': { emoji: '📐', color: 'from-teal-400 to-emerald-500', bg: 'bg-teal-50' },
    '精灵伙伴': { emoji: '🐱', color: 'from-yellow-400 to-amber-500', bg: 'bg-yellow-50' },
  };

  const npc = $derived(npcInfo[initial.npcName] || { emoji: '💬', color: 'from-indigo-400 to-purple-500', bg: 'bg-indigo-50' });

  // NPC → subject mapping for study tasks
  const NPC_SUBJECT_MAP: Record<string, string> = {
    '李白': 'chinese',
    '李清照': 'chinese',
    '智慧老人': 'math',
    '毕达哥拉斯': 'math',
    '梅林导师': 'english',
  };

  // Derive default subject from NPC, but allow user to override for general chapters
  const defaultSubject = $derived(NPC_SUBJECT_MAP[initial.npcName] ?? null);
  let studySubject = $state<string | null>(defaultSubject);

  const subjectEmoji: Record<string, string> = {
    chinese: '📜', math: '🔢', english: '🔤'
  };

  const subjectName: Record<string, string> = {
    chinese: '语文', math: '数学', english: '英语'
  };

  let synth: SpeechSynthesis | null = null;

  onMount(() => {
    speechSupported = 'speechSynthesis' in window;
    if (speechSupported) {
      synth = window.speechSynthesis;
    }
  });

  function speakText(text: string) {
    if (!synth || !speechSupported) return;
    synth.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'zh-CN';
    utterance.rate = 0.9;
    utterance.pitch = 1.1;
    synth.speak(utterance);
  }

  function stopSpeaking() {
    if (synth) synth.cancel();
  }

  function typeText(text: string, callback?: () => void) {
    isTyping = true;
    displayText = '';
    speakText(text);
    let i = 0;
    const interval = setInterval(() => {
      displayText = text.slice(0, i + 1);
      i++;
      if (i >= text.length) {
        clearInterval(interval);
        isTyping = false;
        if (callback) callback();
      }
    }, 35);
    return () => clearInterval(interval);
  }

  let currentCleanup: (() => void) | null = null;

  function enterDialogue() {
    phase = 'dialogue';
    dialogueIndex = 0;
    if (currentCleanup) currentCleanup();
    currentCleanup = typeText(currentLine);
    soundManager.playClick();
  }

  function nextDialogue() {
    if (isTyping) {
      if (currentCleanup) currentCleanup();
      displayText = currentLine;
      isTyping = false;
      return;
    }
    if (dialogueIndex < dialogueLines.length - 1) {
      dialogueIndex++;
      if (currentCleanup) currentCleanup();
      currentCleanup = typeText(currentLine);
    } else {
      stopSpeaking();
      phase = 'choice';
      soundManager.playComplete();
    }
  }

  function startStudy() {
    soundManager.playClick();
    phase = 'study';
  }

  function handleStudyComplete(result: StudyResult) {
    studyResult = result;
    soundManager.stopBGM();
    completeChapter(initial.id).catch(() => {});
    phase = 'study_result';
  }

  function handleStudyCancel() {
    soundManager.stopBGM();
    completeChapter(initial.id).catch(() => {});
    handleClose();
  }

  function skipToDone() {
    stopSpeaking();
    phase = 'done';
    soundManager.playCelebrate();
    completeChapter(initial.id).catch(() => {});
  }

  function handleClose() {
    stopSpeaking();
    closing = true;
    setTimeout(() => {
      if (initial.rewardEnergy > 0) {
        toastStore.success(`完成剧情！获得 ⚡${initial.rewardEnergy} 能量`);
      }
      onClose();
    }, 400);
  }
</script>

<div
  class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-8 overflow-y-auto"
  class:animate-fade-in={!closing}
  class:animate-fade-out={closing}
  role="dialog"
  tabindex="0"
  onkeydown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      if (phase === 'narrative') enterDialogue();
      else if (phase === 'dialogue') nextDialogue();
      else if (phase === 'choice') startStudy();
    }
  }}
>
  <!-- Scene background -->
  <div class="fixed inset-0 bg-gradient-to-b from-indigo-950/80 via-purple-900/70 to-indigo-950/80 backdrop-blur-sm"></div>

  <!-- Floating particles -->
  <div class="fixed inset-0 overflow-hidden pointer-events-none">
    {#each Array(8) as _, i}
      <div
        class="absolute text-xs animate-float"
        style="left: {Math.random() * 100}%; top: {Math.random() * 100}%; animation-delay: {i * 0.4}s; opacity: 0.3;"
      >✨</div>
    {/each}
  </div>

  <!-- Dialog card -->
  <!-- svelte-ignore a11y_no_static_element_interactions a11y_click_events_have_key_events -->
  <div
    role="presentation"
    class="relative bg-white/95 backdrop-blur rounded-2xl shadow-2xl w-full p-6 sm:p-8 animate-scale-in z-10
      {phase === 'study' || phase === 'study_result' ? 'max-w-xl' : 'max-w-lg'}"
    onclick={(e) => e.stopPropagation()}
  >
    {#if phase === 'narrative'}
      <!-- Scene opening -->
      <div class="text-center">
        <div class="text-5xl mb-4 animate-bounce-in">{npc.emoji}</div>
        <div class="inline-block px-3 py-1 rounded-full text-xs font-medium bg-indigo-100 text-indigo-600 mb-3">
          第 {initial.chapterNumber} 章
        </div>
        <h2 class="text-2xl font-bold text-gray-800 mb-4">{initial.title}</h2>
        <div class="bg-gradient-to-r from-indigo-50 to-purple-50 rounded-xl p-5 text-sm text-gray-600 leading-relaxed text-left italic border border-indigo-100">
          "{initial.narrative}"
        </div>
        <button
          onclick={enterDialogue}
          class="mt-6 px-8 py-3 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl font-semibold hover:from-indigo-600 hover:to-purple-700 transition shadow-lg hover:shadow-indigo-200 animate-pulse"
        >
          进入剧情 →
        </button>
      </div>

    {:else if phase === 'dialogue'}
      <!-- NPC dialogue scene -->
      <div class="flex flex-col items-center gap-4">
        <!-- NPC Avatar -->
        <div class="relative">
          <div class="w-20 h-20 rounded-full bg-gradient-to-br {npc.color} flex items-center justify-center text-3xl shadow-lg animate-bounce-in">
            {npc.emoji}
          </div>
          {#if speechSupported}
            <div class="absolute -bottom-1 -right-1 w-5 h-5 bg-green-400 rounded-full flex items-center justify-center">
              <span class="text-white text-xs">{isTyping ? '🔊' : '🔈'}</span>
            </div>
          {/if}
        </div>

        <!-- NPC Name -->
        <p class="text-sm font-bold text-gray-700">{initial.npcName}</p>

        <!-- Dialogue bubble -->
        <div class="bg-gradient-to-br from-gray-50 to-indigo-50 rounded-2xl p-5 w-full border border-indigo-100 min-h-[80px]">
          <p class="text-sm text-gray-700 leading-relaxed">
            {displayText}
            {#if isTyping}
              <span class="inline-block w-1 h-4 bg-indigo-500 ml-0.5 animate-pulse"></span>
            {/if}
          </p>
        </div>

        <!-- Continue button -->
        <button
          onclick={nextDialogue}
          class="text-sm text-gray-400 hover:text-gray-600 transition flex items-center gap-1"
        >
          {isTyping ? '点击跳过' : dialogueIndex < dialogueLines.length - 1 ? '继续对话 →' : '回应 NPC →'}
        </button>
      </div>

    {:else if phase === 'choice'}
      <!-- Player choice → study task -->
      <div class="text-center py-4">
        <div class="text-4xl mb-4 animate-bounce-in">{studySubject ? subjectEmoji[studySubject] || '💬' : '💬'}</div>
        <p class="text-gray-500 text-sm mb-4">
          {studySubject
            ? `学习挑战：${initial.npcName} 想考验你的${subjectName[studySubject] || ''}能力！`
            : '选择你想挑战的学习方向：'}
        </p>

        {#if studySubject}
          <!-- Auto subject: single button -->
          <button
            onclick={startStudy}
            class="w-full px-6 py-4 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl font-semibold hover:from-indigo-600 hover:to-purple-700 transition shadow-lg hover:shadow-indigo-200"
          >
            {initial.choiceText || '接受挑战！'}
          </button>
        {:else}
          <!-- General chapter: 3 subject cards -->
          <div class="grid grid-cols-3 gap-3 mb-4">
            <button
              onclick={() => { studySubject = 'chinese'; startStudy(); }}
              class="flex flex-col items-center p-4 rounded-xl border-2 border-amber-200 bg-amber-50 hover:bg-amber-100 transition"
            >
              <span class="text-3xl mb-1">📜</span>
              <span class="text-xs font-medium text-amber-700">诗词大陆</span>
            </button>
            <button
              onclick={() => { studySubject = 'math'; startStudy(); }}
              class="flex flex-col items-center p-4 rounded-xl border-2 border-blue-200 bg-blue-50 hover:bg-blue-100 transition"
            >
              <span class="text-3xl mb-1">🔢</span>
              <span class="text-xs font-medium text-blue-700">智慧王国</span>
            </button>
            <button
              onclick={() => { studySubject = 'english'; startStudy(); }}
              class="flex flex-col items-center p-4 rounded-xl border-2 border-purple-200 bg-purple-50 hover:bg-purple-100 transition"
            >
              <span class="text-3xl mb-1">🔤</span>
              <span class="text-xs font-medium text-purple-700">魔法学院</span>
            </button>
          </div>
          <button onclick={skipToDone}
            class="text-xs text-gray-400 hover:text-gray-600 transition">
            跳过挑战，完成剧情
          </button>
        {/if}
      </div>

    {:else if phase === 'study'}
      <!-- Mini study task -->
      <div class="py-2">
        <div class="text-center mb-3">
          <span class="text-xs font-medium text-indigo-500 bg-indigo-50 px-3 py-1 rounded-full">
            {studySubject === 'chinese' ? '📜 诗词大陆' : studySubject === 'math' ? '🔢 智慧王国' : '🔤 魔法学院'} · 学习挑战
          </span>
        </div>
        <StoryStudyTask
          subject={studySubject || 'chinese'}
          npcName={initial.npcName}
          chapterTitle={initial.title}
          onComplete={handleStudyComplete}
          onCancel={handleStudyCancel}
        />
      </div>

    {:else if phase === 'study_result' && studyResult}
      <!-- Study result -->
      <div class="text-center py-4">
        <div class="text-5xl mb-4 animate-bounce-in">
          {studyResult.passed ? '🎉' : '💪'}
        </div>
        <h3 class="text-lg font-bold text-gray-800 mb-2">
          {studyResult.passed ? '挑战通过！' : '继续加油！'}
        </h3>
        {#if studyResult.totalQuestions > 0}
          <div class="bg-gray-50 rounded-xl p-4 text-sm space-y-2 mb-4 text-left">
            <div class="flex justify-between">
              <span class="text-gray-500">正确率</span>
              <span class="font-bold {studyResult.accuracy >= 0.8 ? 'text-green-600' : studyResult.accuracy >= 0.6 ? 'text-yellow-600' : 'text-red-600'}">
                {Math.round(studyResult.accuracy * 100)}%
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">答题</span>
              <span>{studyResult.correctAnswers}/{studyResult.totalQuestions}</span>
            </div>
            {#if studyResult.maxCombo >= 2}
              <div class="flex justify-between">
                <span class="text-gray-500">最高连击</span>
                <span class="text-orange-500 font-bold">🔥 ×{studyResult.maxCombo >= 4 ? 2 : 1.5}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-gray-500">Boss</span>
              <span class={studyResult.bossDefeated ? 'text-green-600' : 'text-red-500'}>
                {studyResult.bossDefeated ? '✅ 击败' : '❌'}
              </span>
            </div>
            {#if studyResult.treasuresFound > 0}
              <div class="flex justify-between">
                <span class="text-gray-500">宝箱</span>
                <span class="text-amber-600">{studyResult.treasuresFound} 个</span>
              </div>
            {/if}
          </div>
        {/if}
        <button
          onclick={() => { phase = 'done'; soundManager.playCelebrate(); }}
          class="px-8 py-3 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl font-semibold hover:from-indigo-600 hover:to-purple-700 transition shadow-lg"
        >
          完成剧情 →
        </button>
      </div>

    {:else if phase === 'done'}
      <!-- Chapter complete -->
      <div class="text-center py-6">
        <div class="text-6xl mb-4 animate-celebration">✨</div>
        <h2 class="text-xl font-bold text-gray-800 mb-2">章节完成！</h2>
        <p class="text-sm text-gray-500 mb-4">"{initial.title}"</p>
        {#if initial.rewardEnergy > 0}
          <div class="inline-block bg-amber-100 rounded-full px-6 py-2 mb-4">
            <span class="text-amber-600 font-bold text-lg">+{initial.rewardEnergy}</span>
            <span class="text-amber-500 text-sm"> 能量</span>
          </div>
        {/if}
        <button
          onclick={handleClose}
          class="px-8 py-3 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition"
        >
          关闭
        </button>
      </div>
    {/if}
  </div>
</div>

<style>
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes fadeOut { from { opacity: 1; } to { opacity: 0; } }
  @keyframes scaleIn { from { opacity: 0; transform: scale(0.9); } to { opacity: 1; transform: scale(1); } }
  :global(.animate-fade-in) { animation: fadeIn 0.4s ease-out; }
  :global(.animate-fade-out) { animation: fadeOut 0.3s ease-out forwards; }
  :global(.animate-scale-in) { animation: scaleIn 0.3s ease-out; }
</style>
