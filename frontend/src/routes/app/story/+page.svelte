<script lang="ts">
  import { onMount } from 'svelte';
  import { storyStore } from '$lib/stores/story.svelte';
  import { claimChapterReward, checkStoryConditions } from '$lib/api/story';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { soundManager } from '$lib/audio/sound-manager';
  import ChapterDialog from '$lib/components/story/ChapterDialog.svelte';
  import StoryMap from '$lib/components/story/StoryMap.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import SkeletonTemplates from '$lib/components/common/SkeletonTemplates.svelte';
  import ErrorState from '$lib/components/common/ErrorState.svelte';

  let loading = $state(true);
  let loadError = $state('');
  let viewingChapter = $state<any>(null);
  let claiming = $state<number | null>(null);

  async function load() {
    loading = true;
    loadError = '';
    try {
      await checkStoryConditions();
      await storyStore.refresh();
    } catch (e) {
      loadError = '加载剧情失败';
    }
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

  const totalChapters = $derived(storyStore.chapters.length);
  const progressPct = $derived(totalChapters > 0 ? (storyStore.completedCount / totalChapters) * 100 : 0);
</script>

<svelte:head>
  <title>剧情 - Pet Grow Up</title>
</svelte:head>

<div class="relative min-h-screen overflow-hidden"
     style="background: radial-gradient(ellipse at 50% 0%, #1e1b4b 0%, #0f0d1f 50%, #020617 100%);">
  <!-- Map header -->
  <div class="relative z-10 max-w-4xl mx-auto px-4 pt-6 pb-2">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-white">✨ 学习能量宇宙</h1>
      <p class="text-indigo-300 text-sm mt-1">你的冒险旅程</p>
      {#if !loading && !loadError}
        <div class="mt-3 flex items-center justify-center gap-4 text-sm max-w-sm mx-auto">
          <span class="text-indigo-300">探索进度</span>
          <div class="flex-1 bg-indigo-800/50 rounded-full h-2">
            <div class="bg-gradient-to-r from-amber-400 via-purple-400 to-indigo-300 h-2 rounded-full transition-all duration-700"
              style="width: {progressPct}%"></div>
          </div>
          <span class="text-indigo-300 text-xs">{storyStore.completedCount}/{totalChapters}</span>
        </div>
      {/if}
    </div>
  </div>

  <!-- Story adventure map -->
  <div class="relative z-10 max-w-4xl mx-auto px-4 pb-16">
    {#if loading}
      <div class="py-12"><SkeletonTemplates name="study" /></div>
    {:else if loadError}
      <ErrorState type="server" message={loadError} onRetry={load} />
    {:else}
      <StoryMap
        chapters={storyStore.chapters}
        spiritSpecies={spiritStore.activeSpirit?.species ?? null}
        evolutionStage={spiritStore.activeSpirit?.currentEvolutionStage ?? 1}
        claimingId={claiming}
        onChapterClick={(ch) => { viewingChapter = ch; }}
        onClaimReward={handleClaim}
      />
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