<script lang="ts">
  import { onMount } from 'svelte';
  import { storyStore } from '$lib/stores/story.svelte';
  import { claimChapterReward, checkStoryConditions } from '$lib/api/story';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { soundManager } from '$lib/audio/sound-manager';
  import ChapterDialog from '$lib/components/story/ChapterDialog.svelte';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';

  let loading = $state(true);
  let viewingChapter = $state<any>(null);
  let claiming = $state<number | null>(null);

  async function load() {
    loading = true;
    await checkStoryConditions();
    await storyStore.refresh();
    loading = false;

    const latest = storyStore.latestUnlocked;
    if (latest) viewingChapter = latest;
  }

  async function handleClaim(chapterId: number) {
    claiming = chapterId;
    try {
      await claimChapterReward(chapterId);
      toastStore.success('领取章节奖励成功！');
      authStore.refreshProfile();
      await storyStore.refresh();
    } catch (e: any) {
      toastStore.error(e.message || '领取失败');
    } finally {
      claiming = null;
    }
  }

  onMount(load);

  // Map constants
  const CHAPTER_HEIGHT = 130;
  const CENTER = 50; // percentage

  // Chapter subject mapping for themed colors/emojis
  const NPC_SUBJECT_MAP: Record<string, string> = {
    '李白': 'chinese', '李清照': 'chinese',
    '智慧老人': 'math', '毕达哥拉斯': 'math',
    '梅林导师': 'english',
  };

  const subjectTheme: Record<string, { glow: string; node: string; ring: string; from: string; to: string; emoji: string }> = {
    chinese: { glow: 'shadow-amber-400/50', node: 'bg-amber-400', ring: 'ring-amber-200', from: 'from-amber-500', to: 'to-orange-500', emoji: '📜' },
    math: { glow: 'shadow-blue-400/50', node: 'bg-blue-400', ring: 'ring-blue-200', from: 'from-blue-500', to: 'to-cyan-500', emoji: '🔢' },
    english: { glow: 'shadow-purple-400/50', node: 'bg-purple-400', ring: 'ring-purple-200', from: 'from-purple-500', to: 'to-pink-500', emoji: '🔤' },
  };

  function getSubject(ch: any): string | null {
    return NPC_SUBJECT_MAP[ch.npcName] ?? null;
  }

  function getNodeSide(i: number): 'left' | 'right' {
    return i % 2 === 0 ? 'left' : 'right';
  }

  function getSpiritTop(): number {
    const idx = storyStore.chapters.findIndex(c => c.unlocked && !c.completed);
    return idx >= 0 ? idx * CHAPTER_HEIGHT + CHAPTER_HEIGHT / 2 : 0;
  }

  // Background star positions (stable across renders)
  const bgStars = Array.from({ length: 40 }, () => ({
    left: Math.random() * 100,
    top: Math.random() * 100,
    size: 1 + Math.random() * 2,
    delay: Math.random() * 3,
    duration: 2 + Math.random() * 3
  }));
</script>

<svelte:head>
  <title>剧情 - Pet Grow Up</title>
</svelte:head>

<div class="relative min-h-screen bg-gradient-to-b from-indigo-950 via-purple-950 to-slate-900 overflow-hidden">
  <!-- Background starfield -->
  <div class="fixed inset-0 pointer-events-none">
    {#each bgStars as star}
      <div
        class="absolute rounded-full bg-white animate-pulse"
        style="left: {star.left}%; top: {star.top}%; width: {star.size}px; height: {star.size}px;
               animation-delay: {star.delay}s; animation-duration: {star.duration}s; opacity: 0.3;"
      ></div>
    {/each}
  </div>

  <!-- Map header -->
  <div class="relative z-10 max-w-4xl mx-auto px-4 pt-6 pb-2">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-white">✨ 学习能量宇宙</h1>
      <p class="text-indigo-300 text-sm mt-1">你的冒险旅程</p>
      {#if !loading}
        <div class="mt-3 flex items-center justify-center gap-4 text-sm max-w-sm mx-auto">
          <span class="text-indigo-300">进度: {storyStore.completedCount}/12</span>
          <div class="flex-1 bg-indigo-800/50 rounded-full h-2">
            <div class="bg-gradient-to-r from-amber-400 via-purple-400 to-indigo-300 h-2 rounded-full transition-all duration-700"
              style="width: {(storyStore.completedCount / 12) * 100}%"></div>
          </div>
        </div>
      {/if}
    </div>
  </div>

  <!-- Map content -->
  <div class="relative z-10 max-w-4xl mx-auto px-4 pb-16">
    {#if loading}
      <div class="text-center text-indigo-300/50 py-32">✨ 加载冒险地图...</div>
    {:else}
      <div class="relative" style="height: {storyStore.chapters.length * CHAPTER_HEIGHT + 80}px">
        <!-- Constellation path (vertical dotted line) -->
        <div class="absolute left-1/2 top-0 bottom-0 w-0.5 -translate-x-1/2"
             style="background: repeating-linear-gradient(to bottom, rgba(139, 92, 246, 0.4) 0px, rgba(139, 92, 246, 0.4) 6px, transparent 6px, transparent 12px);">
        </div>

        <!-- Subject region nebulas -->
        {#each storyStore.chapters as ch, i}
          {@const subj = getSubject(ch)}
          {#if subj}
            <div
              class="absolute left-1/2 -translate-x-1/2 rounded-full pointer-events-none"
              style="width: 280px; height: 100px; top: {i * CHAPTER_HEIGHT + 15}px;
                     background: radial-gradient(ellipse, {subj === 'chinese' ? 'rgba(251, 191, 36, 0.06)' : subj === 'math' ? 'rgba(96, 165, 250, 0.06)' : 'rgba(168, 85, 247, 0.06)'}, transparent 70%);">
            </div>
          {/if}
        {/each}

        <!-- Chapter nodes -->
        {#each storyStore.chapters as ch, i}
          {@const isLeft = getNodeSide(i) === 'left'}
          {@const status = ch.completed ? 'completed' : ch.unlocked ? 'current' : 'locked'}
          {@const subj = getSubject(ch)}
          {@const theme = subj ? subjectTheme[subj] : null}

          <div class="absolute w-full" style="top: {i * CHAPTER_HEIGHT}px; height: {CHAPTER_HEIGHT}px;">
            <!-- Connector line from center to node -->
            <div
              class="absolute top-1/2 h-0.5 -translate-y-1/2"
              style="{isLeft ? 'right: 5%' : 'left: 5%'}; width: calc(40% - 1rem);
                     background: linear-gradient(to {isLeft ? 'left' : 'right'},
                       {status === 'completed' ? 'rgba(74, 222, 128, 0.3)' : status === 'current' ? 'rgba(129, 140, 248, 0.3)' : 'rgba(107, 114, 128, 0.15)'},
                       {status === 'completed' ? 'rgba(74, 222, 128, 0.6)' : status === 'current' ? 'rgba(129, 140, 248, 0.6)' : 'rgba(107, 114, 128, 0.3)'});">
            </div>

            <!-- Node circle (on the path) -->
            <div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-20">
              <div
                class="w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold shadow-lg transition-all duration-500
                  {status === 'completed' ? 'bg-emerald-400 text-white shadow-emerald-400/30 scale-100' :
                   status === 'current' ? 'bg-indigo-500 text-white shadow-indigo-400/40 scale-110 ring-2 ring-indigo-300/50' :
                   'bg-gray-700/50 text-gray-500 scale-90'}"
              >
                {status === 'completed' ? '✓' : ch.chapterNumber}
              </div>
              <!-- Current node pulse ring -->
              {#if status === 'current'}
                <div class="absolute inset-0 rounded-full animate-ping ring-2 ring-indigo-400/30"></div>
              {/if}
            </div>

            <!-- Chapter content card -->
            <div class="absolute top-1/2 -translate-y-1/2 w-[40%]
                        {isLeft ? 'left-[5%]' : 'right-[5%]'}">
              <div
                role="button"
                tabindex="0"
                onkeydown={(e) => { if ((e.key === 'Enter' || e.key === ' ') && status !== 'locked') viewingChapter = ch; }}
                class="rounded-xl p-3.5 border transition-all duration-300 cursor-pointer
                  {status === 'locked'
                    ? 'bg-gray-800/20 border-gray-700/30 opacity-40 backdrop-blur-sm'
                    : status === 'completed'
                      ? 'bg-emerald-900/20 border-emerald-700/30 hover:bg-emerald-800/30 hover:border-emerald-600/50'
                      : 'bg-indigo-900/30 border-indigo-500/40 hover:bg-indigo-800/40 hover:border-indigo-400/60 hover:shadow-lg hover:shadow-indigo-500/10'}"
                onclick={() => { if (status !== 'locked') viewingChapter = ch; }}
              >
                <div class="flex items-center gap-2 mb-1.5">
                  <!-- Subject badge -->
                  {#if subj && theme}
                    <span class="text-sm">{theme.emoji}</span>
                  {/if}
                  <!-- Chapter number -->
                  <span class="text-[11px] font-mono px-1.5 py-0.5 rounded
                    {status === 'completed' ? 'bg-emerald-600/30 text-emerald-300' :
                     status === 'current' ? 'bg-indigo-600/30 text-indigo-300' :
                     'bg-gray-700/30 text-gray-500'}">
                    #{ch.chapterNumber}
                  </span>
                  <!-- Title -->
                  <span class="text-sm font-bold {status === 'locked' ? 'text-gray-500' : 'text-white'}">
                    {ch.title}
                  </span>
                </div>

                <!-- NPC name -->
                {#if ch.npcName}
                  <p class="text-xs {status === 'locked' ? 'text-gray-600' : 'text-indigo-300/70'}">{ch.npcName}</p>
                {/if}

                <!-- Action -->
                <div class="mt-2">
                  {#if status === 'locked'}
                    <span class="text-[11px] text-gray-600">🔒 未解锁</span>
                  {:else if status === 'completed' && !ch.rewardClaimed}
                    <button onclick={(e) => { e.stopPropagation(); handleClaim(ch.id); }} disabled={claiming === ch.id}
                      class="px-2.5 py-1 text-xs bg-amber-500/80 text-white rounded-lg hover:bg-amber-500 transition disabled:opacity-50">
                      {claiming === ch.id ? '领取中...' : `领取 ⚡${ch.rewardEnergy}`}
                    </button>
                  {:else if status === 'completed'}
                    <span class="text-[11px] text-emerald-400/70">✅ 已征服</span>
                  {:else}
                    <span class="text-[11px] text-indigo-300 animate-pulse">🔓 点击进入</span>
                  {/if}
                </div>
              </div>
            </div>
          </div>
        {/each}

        <!-- Spirit avatar tracking current chapter -->
        {#if spiritStore.activeSpirit?.species}
          {@const currentIdx = storyStore.chapters.findIndex(c => c.unlocked && !c.completed)}
          {#if currentIdx >= 0}
            <div class="absolute left-1/2 z-30 transition-all duration-700 ease-in-out"
              style="top: {currentIdx * CHAPTER_HEIGHT + CHAPTER_HEIGHT / 2 - 20}px;">
              <div class="bg-indigo-500/30 rounded-full p-1 shadow-lg shadow-indigo-500/30 backdrop-blur-sm">
                <SpiritAvatar
                  species={spiritStore.activeSpirit.species}
                  evolutionStage={spiritStore.activeSpirit.currentEvolutionStage}
                  size="sm"
                  mood={storyStore.completedCount >= 6 ? 'excited' : 'happy'}
                />
              </div>
            </div>
          {/if}
        {/if}

        <!-- End marker -->
        <div class="absolute left-1/2 -translate-x-1/2 text-center"
             style="top: {storyStore.chapters.length * CHAPTER_HEIGHT + 20}px;">
          <div class="text-indigo-400/30 text-xs">
            {storyStore.completedCount >= 12 ? '🏆 冒险完成！' : '✦ 旅程继续...'}
          </div>
        </div>
      </div>
    {/if}
  </div>
</div>

{#if viewingChapter}
  <ChapterDialog
    chapter={viewingChapter}
    onClose={() => {
      viewingChapter = null;
      storyStore.refresh();
    }}
  />
{/if}
