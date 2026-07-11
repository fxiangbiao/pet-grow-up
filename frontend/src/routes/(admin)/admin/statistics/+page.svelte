<script lang="ts">
  import { onMount } from 'svelte';
  import { adminApi, type Overview, type StudyStats, type EnergyStats, type AchievementStats } from '$lib/api/admin';
  import { ENERGY_SOURCE_LABELS, ACHIEVEMENT_CATEGORY_LABELS, ACHIEVEMENT_RARITY_LABELS } from '$lib/components/admin/constants';

  let overview = $state<Overview | null>(null);
  let studyStats = $state<StudyStats | null>(null);
  let energyStats = $state<EnergyStats | null>(null);
  let achievementStats = $state<AchievementStats | null>(null);
  let loading = $state(true);
  let errorMsg = $state<string | null>(null);
  let days = $state(7);

  onMount(() => { loadAll(); });

  async function loadAll() {
    loading = true;
    errorMsg = null;
    try {
      const [ov, study, energy, ach] = await Promise.all([
        adminApi.getOverview(),
        adminApi.getStudyStats(days),
        adminApi.getEnergyStats(days),
        adminApi.getAchievementStats(),
      ]);
      overview = ov;
      studyStats = study;
      energyStats = energy;
      achievementStats = ach;
    } catch (e: any) {
      errorMsg = e.message || '加载数据失败，请确认后端服务已启动';
    } finally {
      loading = false;
    }
  }

  async function changeDays(d: number) {
    days = d;
    try {
      const [study, energy] = await Promise.all([
        adminApi.getStudyStats(days),
        adminApi.getEnergyStats(days),
      ]);
      studyStats = study;
      energyStats = energy;
    } catch (e: any) {
      // keep existing data
    }
  }

  // Chart helpers
  function maxValue(points: { date: string; value: number }[] | null | undefined): number {
    if (!points || points.length === 0) return 1;
    return Math.max(...points.map(p => p.value), 1);
  }

  function barHeight(value: number, max: number): string {
    return `${Math.max(2, (value / max) * 100)}%`;
  }

  function shortDate(dateStr: string): string {
    return dateStr?.slice(5) || '';
  }

  const overviewCards = $derived(overview ? [
    { label: '总用户', value: overview.totalUsers, color: 'indigo' },
    { label: '学生', value: overview.totalStudents, color: 'blue' },
    { label: '管理员', value: overview.totalAdmins, color: 'purple' },
    { label: '题库', value: overview.totalQuestions, color: 'emerald' },
    { label: '学习场次', value: overview.totalStudySessions, color: 'amber' },
    { label: '能量产出', value: '⚡' + overview.totalEnergyEarned, color: 'green' },
    { label: '能量消耗', value: '⚡' + overview.totalEnergySpent, color: 'rose' },
    { label: '今日活跃', value: overview.todayActiveUsers, color: 'cyan' },
  ] : []);
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">📊 统计仪表盘</h2>
    <div class="flex gap-1 bg-white rounded-lg border p-1">
      {#each [7, 14, 30] as d}
        <button onclick={() => changeDays(d)}
                class="px-3 py-1 text-sm rounded {days === d ? 'bg-indigo-600 text-white' : 'text-gray-600 hover:bg-gray-50'}">
          {d}天
        </button>
      {/each}
    </div>
  </div>

  {#if loading}
    <div class="text-center text-gray-400 py-12">加载中...</div>
  {:else if errorMsg}
    <div class="text-center py-12">
      <div class="text-red-500 text-sm bg-red-50 rounded-lg p-4 inline-block max-w-lg">{errorMsg}</div>
    </div>
  {:else}
    <!-- Overview cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
      {#each overviewCards as card}
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div class="text-xs text-gray-400 mb-1">{card.label}</div>
          <div class="text-2xl font-bold text-gray-800">{card.value}</div>
        </div>
      {/each}
    </div>

    <!-- Study trends -->
    {#if studyStats}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <!-- Daily sessions -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">每日学习场次（近{days}天）</h3>
          <div class="flex items-end gap-1 h-40">
            {#each studyStats.dailySessions as point}
              <div class="flex-1 flex flex-col items-center justify-end">
                <div class="w-full bg-indigo-500 rounded-t transition-all hover:bg-indigo-600"
                     style="height: {barHeight(point.value, maxValue(studyStats.dailySessions))}"></div>
                <div class="text-[10px] text-gray-400 mt-1 -rotate-45 origin-center whitespace-nowrap">{shortDate(point.date)}</div>
              </div>
            {:else}
              <div class="text-gray-300 text-sm m-auto">暂无数据</div>
            {/each}
          </div>
        </div>

        <!-- Daily active users -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">每日活跃用户（近{days}天）</h3>
          <div class="flex items-end gap-1 h-40">
            {#each studyStats.dailyActiveUsers as point}
              <div class="flex-1 flex flex-col items-center justify-end">
                <div class="w-full bg-cyan-500 rounded-t transition-all hover:bg-cyan-600"
                     style="height: {barHeight(point.value, maxValue(studyStats.dailyActiveUsers))}"></div>
                <div class="text-[10px] text-gray-400 mt-1 -rotate-45 origin-center whitespace-nowrap">{shortDate(point.date)}</div>
              </div>
            {:else}
              <div class="text-gray-300 text-sm m-auto">暂无数据</div>
            {/each}
          </div>
        </div>
      </div>
    {/if}

    <!-- Energy flow -->
    {#if energyStats}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <!-- Daily energy earned vs spent -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">每日能量产出/消耗（近{days}天）</h3>
          <div class="flex items-end gap-1 h-40">
            {#each energyStats.dailyEarned as point, i}
              <div class="flex-1 flex flex-col items-center justify-end gap-0.5">
                <div class="w-full bg-green-500 rounded-t transition-all hover:bg-green-600"
                     style="height: {barHeight(point.value, maxValue(energyStats.dailyEarned))}"></div>
                <div class="w-full bg-rose-400 rounded-t transition-all hover:bg-rose-500"
                     style="height: {barHeight(energyStats.dailySpent[i]?.value ?? 0, maxValue(energyStats.dailySpent))}"></div>
                <div class="text-[10px] text-gray-400 mt-1 -rotate-45 origin-center whitespace-nowrap">{shortDate(point.date)}</div>
              </div>
            {:else}
              <div class="text-gray-300 text-sm m-auto">暂无数据</div>
            {/each}
          </div>
          <div class="flex gap-4 mt-2 text-xs">
            <span class="flex items-center gap-1"><span class="w-3 h-3 bg-green-500 rounded"></span>产出</span>
            <span class="flex items-center gap-1"><span class="w-3 h-3 bg-rose-400 rounded"></span>消耗</span>
          </div>
        </div>

        <!-- Energy by source -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">能量产出来源分布</h3>
          <div class="space-y-2">
            {#each energyStats.bySource as source}
              <div class="flex items-center gap-2">
                <span class="text-xs text-gray-500 w-20 text-right">{ENERGY_SOURCE_LABELS[source.source] || source.source}</span>
                <div class="flex-1 bg-gray-100 rounded-full h-5 overflow-hidden">
                  <div class="bg-green-500 h-full rounded-full transition-all"
                       style="width: {barHeight(source.totalAmount, maxValue(energyStats.bySource))}"></div>
                </div>
                <span class="text-xs text-gray-600 w-16">⚡{source.totalAmount}</span>
                <span class="text-xs text-gray-400 w-12">{source.count}次</span>
              </div>
            {:else}
              <div class="text-gray-300 text-sm text-center py-8">暂无数据</div>
            {/each}
          </div>
        </div>
      </div>
    {/if}

    <!-- Achievement stats -->
    {#if achievementStats}
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <h3 class="text-sm font-semibold text-gray-700 mb-3">成就解锁统计</h3>
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b">
            <tr>
              <th class="text-left px-3 py-2 font-medium text-gray-500">成就</th>
              <th class="text-left px-3 py-2 font-medium text-gray-500">分类</th>
              <th class="text-left px-3 py-2 font-medium text-gray-500">稀有度</th>
              <th class="text-center px-3 py-2 font-medium text-gray-500">解锁人数</th>
              <th class="text-center px-3 py-2 font-medium text-gray-500">总用户</th>
              <th class="text-left px-3 py-2 font-medium text-gray-500">解锁率</th>
            </tr>
          </thead>
          <tbody class="divide-y">
            {#each achievementStats.achievements as ach}
              <tr class="hover:bg-gray-50">
                <td class="px-3 py-2 font-medium">{ach.name}</td>
                <td class="px-3 py-2">
                  <span class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                    {ACHIEVEMENT_CATEGORY_LABELS[ach.category] || ach.category}
                  </span>
                </td>
                <td class="px-3 py-2">
                  <span class="text-xs px-2 py-0.5 rounded-full
                    {ach.rarity === 'LEGENDARY' ? 'bg-amber-100 text-amber-700' :
                     ach.rarity === 'EPIC' ? 'bg-purple-100 text-purple-700' :
                     ach.rarity === 'RARE' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}">
                    {ACHIEVEMENT_RARITY_LABELS[ach.rarity] || ach.rarity}
                  </span>
                </td>
                <td class="px-3 py-2 text-center">{ach.unlockedCount}</td>
                <td class="px-3 py-2 text-center text-gray-400">{ach.totalUsers}</td>
                <td class="px-3 py-2">
                  <div class="flex items-center gap-2">
                    <div class="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden max-w-[120px]">
                      <div class="bg-indigo-500 h-full rounded-full"
                           style="width: {Math.min(100, ach.unlockRate)}%"></div>
                    </div>
                    <span class="text-xs text-gray-500">{ach.unlockRate.toFixed(1)}%</span>
                  </div>
                </td>
              </tr>
            {:else}
              <tr><td colspan="6" class="text-center text-gray-400 py-8">暂无数据</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  {/if}
</div>
