<script lang="ts">
  import type { DailyRewardDTO, ClaimResult } from '$lib/api/daily-reward';

  let {
    reward,
    eligible = false,
    claimed = false,
    onclaim,
  }: {
    reward: DailyRewardDTO | null;
    eligible: boolean;
    claimed: boolean;
    onclaim?: () => Promise<ClaimResult>;
  } = $props();

  let phase = $state<'idle' | 'shaking' | 'opening' | 'revealed' | 'claimed'>('idle');
  let result = $state<ClaimResult | null>(null);
  let loading = $state(false);

  async function handleOpen() {
    if (!eligible || !onclaim || loading) return;
    loading = true;
    phase = 'shaking';

    // Shake animation ~1.2s
    await new Promise(r => setTimeout(r, 1200));

    try {
      result = await onclaim();
      phase = 'revealed';
    } catch {
      phase = 'idle';
    } finally {
      loading = false;
    }
  }

  function milestoneGlow() {
    if (!reward) return '';
    const day = reward.unlockDay;
    if (day >= 30) return 'shadow-yellow-400/50 shadow-xl ring-2 ring-yellow-400';
    if (day >= 14) return 'shadow-purple-400/50 shadow-lg ring-2 ring-purple-300';
    if (day >= 7) return 'shadow-blue-400/50 shadow-lg ring-2 ring-blue-300';
    if (day >= 3) return 'shadow-orange-400/40 shadow-md ring-1 ring-orange-200';
    return '';
  }
</script>

{#if claimed}
  <!-- Already claimed badge -->
  <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex items-center gap-3">
    <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-lg">✅</div>
    <div>
      <p class="text-sm font-semibold text-gray-800">今日盲盒已领取</p>
      <p class="text-xs text-gray-400">明天再来打开新的惊喜吧！</p>
    </div>
  </div>
{:else if eligible && reward}
  <!-- Claimable blind box -->
  <div class="bg-white rounded-2xl shadow-sm border-2 border-dashed border-indigo-200 p-4 {milestoneGlow()}">
    <div class="flex items-center gap-3">
      {#if phase === 'idle'}
        <div class="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center text-lg animate-bounce">
          🎁
        </div>
        <div class="flex-1">
          <p class="text-sm font-semibold text-gray-800">
            {reward.isMilestone ? `🎉 登录${reward.unlockDay}天里程碑！` : '每日盲盒'}
          </p>
          <p class="text-xs text-gray-500">
            {reward.isMilestone ? reward.description : '点击打开今天的惊喜！'}
          </p>
        </div>
        <button
          onclick={handleOpen}
          disabled={loading}
          class="px-4 py-2 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-lg text-sm font-semibold hover:from-indigo-600 hover:to-purple-600 disabled:opacity-50 transition-all active:scale-95"
        >
          打开
        </button>
      {:else if phase === 'shaking'}
        <div class="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center text-2xl animate-ping">
          🎁
        </div>
        <div class="flex-1">
          <p class="text-sm font-medium text-gray-700">正在打开...</p>
          <div class="flex gap-1 mt-1">
            <span class="inline-block w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce" style="animation-delay:0ms"></span>
            <span class="inline-block w-1.5 h-1.5 bg-purple-400 rounded-full animate-bounce" style="animation-delay:150ms"></span>
            <span class="inline-block w-1.5 h-1.5 bg-pink-400 rounded-full animate-bounce" style="animation-delay:300ms"></span>
          </div>
        </div>
      {:else if phase === 'revealed' && result}
        <div class="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center text-2xl animate-bounce-in">
          {result.itemIcon || result.rewardType === 'ENERGY' ? '⚡' : '✨'}
        </div>
        <div class="flex-1">
          <p class="text-sm font-bold text-indigo-700">
            {result.isMilestone ? result.milestoneName || '里程碑奖励!' : '恭喜获得!'}
          </p>
          <p class="text-xs text-gray-600">
            {#if result.energyEarned > 0}
              +{result.energyEarned} ⚡ 学习能量
            {:else if result.itemName}
              {result.itemIcon || '📦'} {result.itemName}
            {/if}
          </p>
          <p class="text-xs text-gray-400 mt-0.5">连续登录 {result.consecutiveLoginDays} 天</p>
        </div>
      {/if}
    </div>
  </div>
{:else}
  <!-- Not eligible (shouldn't happen normally, but guard) -->
  <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
    <p class="text-sm text-gray-400 text-center">暂无可领取的奖励</p>
  </div>
{/if}
