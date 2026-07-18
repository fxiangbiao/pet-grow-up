<script lang="ts">
  import { onMount, onDestroy } from 'svelte';

  interface Props {
    chapter: {
      title: string;
      narrative: string;
      npcName: string;
      npcDialogue: string;
    };
    subject: string;
    onComplete: () => void;
    onSkip: () => void;
  }

  let { chapter, subject, onComplete, onSkip }: Props = $props();

  let displayText = $state('');
  let displayDialogue = $state('');
  let isTypingNarrative = $state(false);
  let isTypingDialogue = $state(false);
  let showButton = $state(false);
  let narrativeInterval: ReturnType<typeof setInterval> | null = null;
  let dialogueInterval: ReturnType<typeof setInterval> | null = null;

  const npcEmojis: Record<string, string> = {
    '智慧老人': '🧙',
    '拼音仙子': '🧚',
    '数字精灵': '🔢',
    '字母巫师': '🧙‍♂️',
    '书仙': '📚',
    '猫博士': '🐱',
    '魔法导师': '🎩',
  };

  const subjectBgs: Record<string, string> = {
    chinese: 'from-amber-900 via-orange-900 to-red-900',
    math: 'from-blue-900 via-indigo-900 to-purple-900',
    english: 'from-purple-900 via-violet-900 to-indigo-900',
  };

  function getNpcEmoji(name: string): string {
    return npcEmojis[name] || '🌟';
  }

  function typeNarrative() {
    isTypingNarrative = true;
    displayText = '';
    let i = 0;
    narrativeInterval = setInterval(() => {
      displayText = chapter.narrative.slice(0, i + 1);
      i++;
      if (i >= chapter.narrative.length) {
        if (narrativeInterval) clearInterval(narrativeInterval);
        isTypingNarrative = false;
        typeDialogue();
      }
    }, 40);
  }

  function typeDialogue() {
    if (!chapter.npcDialogue) {
      showButton = true;
      return;
    }
    isTypingDialogue = true;
    displayDialogue = '';
    let i = 0;
    dialogueInterval = setInterval(() => {
      displayDialogue = chapter.npcDialogue.slice(0, i + 1);
      i++;
      if (i >= chapter.npcDialogue.length) {
        if (dialogueInterval) clearInterval(dialogueInterval);
        isTypingDialogue = false;
        showButton = true;
      }
    }, 50);
  }

  function skipTyping() {
    if (isTypingNarrative) {
      if (narrativeInterval) clearInterval(narrativeInterval);
      isTypingNarrative = false;
      displayText = chapter.narrative;
      typeDialogue();
    } else if (isTypingDialogue) {
      if (dialogueInterval) clearInterval(dialogueInterval);
      isTypingDialogue = false;
      displayDialogue = chapter.npcDialogue;
      showButton = true;
    }
  }

  onMount(() => {
    typeNarrative();
  });

  onDestroy(() => {
    if (narrativeInterval) clearInterval(narrativeInterval);
    if (dialogueInterval) clearInterval(dialogueInterval);
  });
</script>

<div class="chapter-intro bg-gradient-to-b {subjectBgs[subject] || subjectBgs.chinese} text-white p-6 rounded-2xl shadow-xl border-2 border-white/10 relative overflow-hidden">
  <!-- Stars background -->
  {#each Array(8) as _, i}
    <div class="absolute w-1 h-1 bg-white rounded-full animate-pulse"
      style="left: {10 + i * 12}%; top: {5 + (i % 4) * 20}%; animation-delay: {i * 0.3}s; opacity: 0.4;">
    </div>
  {/each}

  <!-- Chapter title -->
  <div class="text-center mb-5 relative z-10">
    <div class="text-4xl mb-2">
      {subject === 'chinese' ? '📜' : subject === 'math' ? '🔢' : '🔤'}
    </div>
    <h2 class="text-2xl font-bold drop-shadow-lg">{chapter.title}</h2>
  </div>

  <!-- Narrative text -->
  <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 mb-4 relative z-10">
    <p class="text-base leading-relaxed text-white/90">{displayText}</p>
    {#if isTypingNarrative}
      <span class="inline-block w-0.5 h-4 bg-white/70 animate-pulse ml-0.5"></span>
    {/if}
  </div>

  <!-- NPC dialogue -->
  {#if chapter.npcName && (displayText.length > 0 || !isTypingNarrative)}
    <div class="bg-white/15 backdrop-blur-sm rounded-xl p-4 mb-4 relative z-10">
      <div class="flex items-center gap-2 mb-2">
        <span class="text-2xl">{getNpcEmoji(chapter.npcName)}</span>
        <span class="font-bold text-sm text-white/80">{chapter.npcName}</span>
      </div>
      <p class="text-base text-white/90">{displayDialogue}</p>
      {#if isTypingDialogue}
        <span class="inline-block w-0.5 h-4 bg-white/70 animate-pulse ml-0.5"></span>
      {/if}
    </div>
  {/if}

  <!-- Actions -->
  <div class="flex gap-3 relative z-10">
    {#if showButton}
      <button onclick={onComplete}
        class="flex-1 py-3 bg-gradient-to-r from-yellow-400 to-orange-500 text-white font-bold rounded-xl hover:from-yellow-500 hover:to-orange-600 transition active:scale-95 shadow-lg text-base">
        开始冒险 →
      </button>
      <button onclick={onSkip}
        class="px-4 py-3 bg-white/10 text-white/60 font-medium rounded-xl hover:bg-white/20 transition text-sm">
        跳过
      </button>
    {:else if isTypingNarrative || isTypingDialogue}
      <button onclick={skipTyping}
        class="flex-1 py-3 bg-white/10 text-white/70 font-medium rounded-xl hover:bg-white/20 transition text-sm">
        跳过动画 ▶
      </button>
    {/if}
  </div>
</div>
