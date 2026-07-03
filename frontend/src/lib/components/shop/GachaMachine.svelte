<script lang="ts">
  import { drawGacha, type GachaResult } from '$lib/api/shop';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';

  let spinning = $state(false);
  let result = $state<GachaResult | null>(null);
  let showResult = $state(false);

  const rarityColors: Record<string, string> = {
    common: 'bg-gray-100 border-gray-300',
    rare: 'bg-purple-50 border-purple-300',
    epic: 'bg-amber-50 border-amber-400',
  };
  const rarityLabels: Record<string, string> = {
    common: '普通',
    rare: '稀有',
    epic: '史诗',
  };

  async function doDraw(free: boolean) {
    if (spinning) return;
    spinning = true;
    result = null;
    showResult = false;
    try {
      result = await drawGacha(free);
      showResult = true;
      authStore.refreshProfile();
      if (result.isNew) {
        toastStore.success(`获得 ${result.name}！`);
      } else if (result.refundEnergy > 0) {
        toastStore.success(`已有 ${result.name}，返还 ⚡${result.refundEnergy}`);
      }
    } catch (e: any) {
      toastStore.error(e.message || '抽取失败');
    } finally {
      spinning = false;
    }
  }
</script>

<div class="bg-white rounded-2xl shadow-sm p-6 text-center">
  <h2 class="text-xl font-bold text-gray-800 mb-1">🎰 星际扭蛋机</h2>
  <p class="text-sm text-gray-500 mb-6">消耗能量抽取随机星灵配饰！</p>

  <!-- Gacha ball display -->
  <div class="relative w-32 h-32 mx-auto mb-6 rounded-full bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500
    shadow-xl flex items-center justify-center"
    class:animate-spin={spinning}>
    {#if spinning}
      <span class="text-3xl">❓</span>
    {:else if result && showResult}
      <span class="text-5xl">{result.iconUrl || '✨'}</span>
    {:else}
      <span class="text-4xl">⭐</span>
    {/if}
  </div>

  <!-- Result reveal -->
  {#if result && showResult}
    <div class="mb-6 p-4 rounded-xl border-2 {rarityColors[result.rarity] || rarityColors.common} animate-fade-in">
      <span class="text-xs px-2 py-0.5 rounded-full font-bold {result.rarity === 'epic' ? 'bg-amber-200 text-amber-800' : result.rarity === 'rare' ? 'bg-purple-200 text-purple-800' : 'bg-gray-200 text-gray-600'}">
        {rarityLabels[result.rarity] || result.rarity}
      </span>
      <p class="text-lg font-bold mt-1">{result.name}</p>
      {#if result.isNew}
        <p class="text-xs text-emerald-500 mt-1">🎉 新配饰！已加入背包</p>
      {:else}
        <p class="text-xs text-amber-500 mt-1">已有此配饰，返还 ⚡{result.refundEnergy}</p>
      {/if}
    </div>
  {/if}

  <!-- Draw buttons -->
  <div class="flex gap-3 justify-center">
    <button
      onclick={() => doDraw(true)}
      disabled={spinning}
      class="px-6 py-3 bg-gradient-to-r from-emerald-400 to-green-500 text-white rounded-xl font-bold
        hover:from-emerald-500 hover:to-green-600 disabled:opacity-40 transition shadow-md">
      🎁 免费抽取
    </button>
    <button
      onclick={() => doDraw(false)}
      disabled={spinning}
      class="px-6 py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl font-bold
        hover:from-indigo-600 hover:to-purple-600 disabled:opacity-40 transition shadow-md">
      🎲 抽取 (⚡50)
    </button>
  </div>
  <p class="text-xs text-gray-400 mt-3">每天首次免费 · 史诗配饰概率 5%</p>
</div>

<style>
  @keyframes fadeIn {
    0% { opacity: 0; transform: scale(0.9); }
    100% { opacity: 1; transform: scale(1); }
  }
  :global(.animate-fade-in) { animation: fadeIn 0.4s ease-out; }
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(720deg); }
  }
  :global(.animate-spin) { animation: spin 0.8s ease-in-out infinite; }
</style>
