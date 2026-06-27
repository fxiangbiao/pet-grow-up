<script lang="ts">
  import { getLeaderboard } from '$lib/api/social';
  import type { LeaderboardEntry } from '$lib/types/api';
  import LoadingSpinner from '$lib/components/common/LoadingSpinner.svelte';
  import EmptyState from '$lib/components/common/EmptyState.svelte';

  type SortType = 'total_energy' | 'streak';

  const sortOptions: { key: SortType; label: string }[] = [
    { key: 'total_energy', label: '总获得' },
    { key: 'streak', label: '连续学习' }
  ];

  let activeSort: SortType = $state('total_energy');
  let entries = $state<LeaderboardEntry[]>([]);
  let loading = $state(true);

  async function load() {
    loading = true;
    try {
      entries = await getLeaderboard(activeSort, 20);
    } catch {}
    loading = false;
  }

  function getRankBadge(rank: number): string {
    if (rank === 1) return '🥇';
    if (rank === 2) return '🥈';
    if (rank === 3) return '🥉';
    return '';
  }

  $effect(() => {
    load();
  });
</script>

<div class="bg-white rounded-2xl shadow-sm p-4">
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-sm font-semibold text-gray-700">排行榜</h2>
    <div class="flex gap-2">
      {#each sortOptions as opt}
        <button
          onclick={() => activeSort = opt.key}
          class="px-3 py-1.5 text-xs rounded-lg transition
            {activeSort === opt.key
              ? 'bg-indigo-100 text-indigo-700'
              : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}"
        >
          {opt.label}
        </button>
      {/each}
    </div>
  </div>

  {#if loading}
    <LoadingSpinner size="sm" text="加载排行榜..." />
  {:else if entries.length === 0}
    <EmptyState icon="🏆" title="暂无排名" message="快去学习获取能量吧！" />
  {:else}
    <div class="space-y-2">
      {#each entries as entry (entry.userId)}
        <div
          class="flex items-center justify-between py-2.5 px-3 rounded-xl transition
            {entry.isCurrentUser ? 'bg-indigo-50 ring-1 ring-indigo-200' : 'hover:bg-gray-50'}"
        >
          <div class="flex items-center gap-3">
            <div class="w-8 text-center">
              {#if entry.rank <= 3}
                <span class="text-lg">{getRankBadge(entry.rank)}</span>
              {:else}
                <span class="text-sm font-mono text-gray-400">{entry.rank}</span>
              {/if}
            </div>
            <div class="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white text-sm font-medium">
              {entry.nickname.charAt(0)}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-gray-700">{entry.nickname}</span>
                {#if entry.isCurrentUser}
                  <span class="text-xs text-indigo-500">(我)</span>
                {/if}
              </div>
            </div>
          </div>
          <div class="text-right">
            <span class="text-sm font-semibold text-amber-500">
              {activeSort === 'streak' ? entry.value + ' 天' : entry.value + ' 点'}
            </span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>
