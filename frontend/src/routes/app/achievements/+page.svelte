<script lang="ts">
  import { onMount } from 'svelte';
  import { achievementStore } from '$lib/stores/achievement.svelte';
  import AchievementCard from '$lib/components/achievement/AchievementCard.svelte';
  import PictureBook from '$lib/components/achievement/PictureBook.svelte';
  import KnowledgeAlbum from '$lib/components/achievement/KnowledgeAlbum.svelte';
  import LoadingSpinner from '$lib/components/common/LoadingSpinner.svelte';
  import EmptyState from '$lib/components/common/EmptyState.svelte';

  const categoryLabels: Record<string, string> = {
    ALL: '全部',
    STUDY: '学习',
    SUBJECT: '学科',
    SPIRIT: '精灵',
    COLLECTION: '收集',
    EVENT: '活动',
    SOCIAL: '社交'
  };

  const categoryIcons: Record<string, string> = {
    ALL: '🏅',
    STUDY: '📚',
    SUBJECT: '📖',
    SPIRIT: '🐱',
    COLLECTION: '🏆',
    EVENT: '🎯',
    SOCIAL: '👥'
  };

  let selectedCategory = $state('ALL');
  let viewMode = $state<'list' | 'book'>('list');
  let categories = $derived(Object.keys(categoryLabels));

  let filteredUnlocked = $derived(
    selectedCategory === 'ALL'
      ? achievementStore.progress?.unlocked ?? []
      : achievementStore.progress?.unlocked.filter(a => a.definition.category === selectedCategory) ?? []
  );

  let filteredInProgress = $derived(
    selectedCategory === 'ALL'
      ? achievementStore.progress?.inProgress ?? []
      : achievementStore.progress?.inProgress.filter(a => a.definition.category === selectedCategory) ?? []
  );

  let filteredTotal = $derived(filteredUnlocked.length + filteredInProgress.length);

  onMount(() => {
    achievementStore.refresh();
  });
</script>

<svelte:head>
  <title>成就 - Pet Grow Up</title>
</svelte:head>

<div class="space-y-6 animate-slide-up">
  <!-- Header -->
  <div class="bg-white rounded-2xl shadow-sm p-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">成就徽章</h1>
        <p class="text-gray-500 mt-1">完成学习任务，解锁成就徽章！</p>
      </div>
      <div class="text-right">
        <div class="flex items-center gap-2 mb-1 justify-end">
          <button onclick={() => viewMode = 'list'} class="px-2 py-1 text-xs rounded {viewMode === 'list' ? 'bg-indigo-100 text-indigo-700' : 'bg-gray-100 text-gray-500'}">列表</button>
          <button onclick={() => viewMode = 'book'} class="px-2 py-1 text-xs rounded {viewMode === 'book' ? 'bg-indigo-100 text-indigo-700' : 'bg-gray-100 text-gray-500'}">图鉴</button>
        </div>
        <p class="text-3xl font-bold text-indigo-500">{achievementStore.unlockedCount}</p>
        <p class="text-sm text-gray-400">/ {achievementStore.totalCount} 已解锁</p>
      </div>
    </div>
    <!-- Progress bar -->
    <div class="mt-4 w-full h-2 bg-gray-100 rounded-full overflow-hidden">
      <div
        class="h-full bg-gradient-to-r from-indigo-400 to-purple-500 rounded-full transition-all duration-500"
        style="width: {achievementStore.totalCount > 0 ? (achievementStore.unlockedCount / achievementStore.totalCount * 100) : 0}%"
      ></div>
    </div>
  </div>

  <!-- Picture Book Mode -->
  {#if viewMode === 'book'}
    <PictureBook>
      <KnowledgeAlbum slot="knowledge" />
      <div slot="adventure" class="text-center py-12 text-gray-400">
        <div class="text-5xl mb-4">🏆</div>
        <p>闯关记录图鉴即将开放</p>
        <p class="text-sm mt-1">完成更多学习冒险来解锁吧！</p>
      </div>
      <div slot="spirit" class="text-center py-12 text-gray-400">
        <div class="text-5xl mb-4">🐱</div>
        <p>星灵成长图鉴即将开放</p>
        <p class="text-sm mt-1">收集更多星灵并进化来填充图鉴！</p>
      </div>
    </PictureBook>
  {:else}
  <!-- Category filter -->
  <div class="flex gap-2 overflow-x-auto pb-2">
    {#each categories as cat}
      <button
        onclick={() => selectedCategory = cat}
        class="flex items-center gap-1.5 px-3 py-2 rounded-xl text-sm font-medium transition whitespace-nowrap
          {selectedCategory === cat
            ? 'bg-indigo-100 text-indigo-700 shadow-sm'
            : 'bg-white text-gray-500 hover:bg-gray-50'}"
      >
        <span>{categoryIcons[cat]}</span>
        {categoryLabels[cat]}
      </button>
    {/each}
  </div>

  <!-- Content -->
  {#if achievementStore.loading}
    <SkeletonTemplates name="achievements" />
  {:else if achievementStore.loadError}
    <div class="max-w-md mx-auto text-center py-12">
      <div class="text-5xl mb-4">🔒</div>
      <p class="text-gray-500 mb-4">{achievementStore.loadError}</p>
      <a href="/login" class="inline-block px-6 py-3 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition">
        重新登录
      </a>
    </div>
  {:else if achievementStore.progress}
    {#if filteredTotal === 0}
      <EmptyState
        icon={categoryIcons[selectedCategory]}
        title="暂无成就"
        message="继续学习来解锁成就吧！"
      />
    {:else}
      {#if filteredUnlocked.length > 0}
        <h2 class="text-lg font-semibold text-gray-700">已解锁</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {#each filteredUnlocked as ua (ua.achievementDefId)}
            <AchievementCard achievement={ua} />
          {/each}
        </div>
      {/if}

      {#if filteredInProgress.length > 0}
        <h2 class="text-lg font-semibold text-gray-700 mt-6">进行中</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {#each filteredInProgress as ua (ua.achievementDefId)}
            <AchievementCard achievement={ua} />
          {/each}
        </div>
      {/if}
    {/if}
  {/if}
  {/if}
</div>
