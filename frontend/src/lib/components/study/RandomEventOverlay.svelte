<script lang="ts">
  import type { RandomEventInfo } from '$lib/api/study';
  import { onMount } from 'svelte';

  let {
    event, onclose,
  }: {
    event: RandomEventInfo;
    onclose: () => void;
  } = $props();

  let visible = $state(false);

  onMount(() => {
    // Delay entrance for dramatic effect
    setTimeout(() => visible = true, 300);
  });

  function getEventEmoji(): string {
    if (event.iconUrl) return event.iconUrl;
    const map: Record<string, string> = {
      BONUS_ENERGY: '⚡',
      SPIRIT_GIFT: '🎁',
      DOUBLE_REWARD: '✨',
      STREAK_BONUS: '🔥',
      FREE_ITEM: '🎰',
    };
    return map[event.eventType] || '🌟';
  }

  let rewardSummary = $derived.by(() => {
    const parts: string[] = [];
    if (event.isDoubleReward) parts.push('能量奖励 ×2！');
    else if (event.bonusEnergy > 0) parts.push(`+${event.bonusEnergy} ⚡ 额外能量`);
    if (event.rewardItemName) parts.push(`获得 ${event.rewardItemName}`);
    if (event.affectionGained > 0) parts.push(`+${event.affectionGained} 好感度`);
    return parts.length > 0 ? parts.join(' · ') : '意外惊喜！';
  });
</script>

{#if visible}
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 transition-opacity duration-300"
       role="dialog" aria-label="随机事件">
    <div class="bg-white rounded-2xl shadow-xl p-6 mx-4 max-w-sm w-full animate-bounce-in text-center relative">
      <!-- Sparkle decoration -->
      <div class="absolute -top-4 left-1/2 -translate-x-1/2">
        <span class="text-4xl animate-pulse">{getEventEmoji()}</span>
      </div>

      <div class="mt-6 mb-3">
        <h2 class="text-xl font-bold text-gray-800">🎉 {event.name}</h2>
      </div>

      <p class="text-sm text-gray-500 mb-2">{event.description}</p>

      <!-- Spirit dialogue -->
      <div class="bg-indigo-50 rounded-xl px-4 py-3 mb-4 relative">
        <div class="text-xs text-indigo-700 italic">"{event.displayText}"</div>
      </div>

      <!-- Reward -->
      <div class="bg-amber-50 rounded-xl px-4 py-3 mb-5">
        <p class="text-sm font-semibold text-amber-700">{rewardSummary}</p>
      </div>

      <button onclick={onclose}
              class="w-full py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-lg font-semibold hover:from-indigo-600 hover:to-purple-600 transition active:scale-95">
        太棒了！
      </button>
    </div>
  </div>
{/if}

<style>
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    50% { transform: scale(1.05); }
    70% { transform: scale(0.95); }
    100% { transform: scale(1); opacity: 1; }
  }
  .animate-bounce-in {
    animation: bounceIn 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55) both;
  }
</style>
