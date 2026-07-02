<script lang="ts">
  import ParticleEffect from '$lib/components/feedback/ParticleEffect.svelte';

  let {
    show = false,
    guardianName = '',
    combo = 0,
    subject = 'math',
    energyBonus = 20,
    onCollect = () => {},
  }: {
    show?: boolean;
    guardianName?: string;
    combo?: number;
    subject?: string;
    energyBonus?: number;
    onCollect?: () => void;
  } = $props();

  let collected = $state(false);
  let showParticles = $state(false);

  $effect(() => {
    if (show) {
      collected = false;
      showParticles = true;
      const t = setTimeout(() => { showParticles = false; }, 3000);
      return () => clearTimeout(t);
    }
  });

  function handleCollect() {
    if (collected) return;
    collected = true;
    onCollect();
  }

  const rewardEmojis = ['💎', '⭐', '✨', '🌟', '💫', '🏆'];
  const comboLabel = $derived(combo >= 5 ? 'MAX COMBO!' : combo >= 3 ? 'HOT STREAK!' : '');
</script>

{#if show && !collected}
  <!-- Particle burst on guardian purified -->
  {#if showParticles}
    <ParticleEffect emojis={rewardEmojis} count={16} spread={90} duration={2500} active={true} />
  {/if}

  <!-- Screen flash — gold (not red) -->
  <div class="fixed inset-0 z-30 pointer-events-none"
    style="animation: reward-bg-flash 0.6s ease-out; background: radial-gradient(circle at center, rgba(255,215,0,0.25) 0%, transparent 70%);">
  </div>

  <!-- Reward card -->
  <div class="fixed inset-0 z-40 flex items-center justify-center">
    <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full mx-4 animate-slide-up border-2 border-amber-200">
      <!-- Header -->
      <div class="text-center mb-4">
        <div class="text-5xl mb-2">🌟</div>
        <h2 class="text-xl font-black text-gray-800">守护者被净化！</h2>
        <p class="text-sm text-violet-500 font-medium">{guardianName} 感谢你的学识之光</p>
      </div>

      <!-- Stats -->
      <div class="bg-gradient-to-r from-violet-50 to-amber-50 rounded-xl p-4 space-y-2 mb-4">
        <div class="flex justify-between text-sm">
          <span class="text-gray-500">连击</span>
          <span class="font-bold text-violet-500">×{combo}
            {#if comboLabel}
              <span class="text-[10px] bg-violet-200 text-violet-700 px-1 py-0.5 rounded ml-1">{comboLabel}</span>
            {/if}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-500">学识证明</span>
          <span class="font-bold text-green-500">✨ 通过考验</span>
        </div>
        <div class="flex justify-between text-sm border-t border-amber-200 pt-2">
          <span class="text-gray-700 font-semibold">能量奖励</span>
          <span class="font-bold text-green-600 text-lg">+{energyBonus}</span>
        </div>
      </div>

      <!-- Collect button -->
      <button
        onclick={handleCollect}
        class="w-full py-3 bg-gradient-to-r from-violet-400 via-purple-400 to-amber-400
          text-white text-lg font-black rounded-xl
          hover:from-violet-300 hover:via-purple-300 hover:to-amber-300
          active:scale-95 transition-all shadow-lg cursor-pointer animate-finishing-pulse">
        🎁 收集守护者的馈赠！
      </button>
    </div>
  </div>
{/if}

<style>
  @keyframes reward-bg-flash {
    0% { opacity: 1; }
    100% { opacity: 0; }
  }
  @keyframes finishingPulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(168, 85, 247, 0.4); }
    50% { box-shadow: 0 0 0 12px rgba(168, 85, 247, 0); }
  }
  :global(.animate-finishing-pulse) {
    animation: finishingPulse 2s ease-in-out infinite;
  }
</style>
