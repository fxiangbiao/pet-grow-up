<script lang="ts">
  import ParticleEffect from '$lib/components/feedback/ParticleEffect.svelte';

  let {
    show = false,
    bossName = '',
    combo = 0,
    subject = 'chinese',
    totalDamage = 0,
    energyBonus = 20,
    onCollect = () => {}
  }: {
    show?: boolean;
    bossName?: string;
    combo?: number;
    subject?: string;
    totalDamage?: number;
    energyBonus?: number;
    onCollect?: () => void;
  } = $props();

  let collected = $state(false);
  let showParticles = $state(false);

  // Trigger particle burst when show becomes true
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

  const lootEmojis = $derived(['💎', '🪙', '⭐', '✨', '💰', '🏆']);
  const comboLabel = $derived(combo >= 4 ? 'MAX COMBO!' : combo >= 2 ? 'HOT STREAK!' : '');
</script>

{#if show && !collected}
  <!-- Particle burst on boss death -->
  {#if showParticles}
    <ParticleEffect emojis={lootEmojis} count={16} spread={90} duration={2500} active={true} />
  {/if}

  <!-- Screen flash on boss death -->
  <div class="fixed inset-0 z-30 pointer-events-none animate-bounce-in"
    style="animation: loot-bg-flash 0.5s ease-out; background: radial-gradient(circle at center, rgba(255,215,0,0.3) 0%, transparent 70%);">
  </div>

  <!-- Loot card -->
  <div class="fixed inset-0 z-40 flex items-center justify-center">
    <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full mx-4 animate-slide-up border-2 border-yellow-300">
      <!-- Header -->
      <div class="text-center mb-4">
        <div class="text-5xl mb-2">🏆</div>
        <h2 class="text-xl font-black text-gray-800">{bossName} 被击败！</h2>
        <p class="text-sm text-yellow-600 font-medium">Boss 奖励</p>
      </div>

      <!-- Stats -->
      <div class="bg-gradient-to-r from-yellow-50 to-amber-50 rounded-xl p-4 space-y-2 mb-4">
        <div class="flex justify-between text-sm">
          <span class="text-gray-500">连击</span>
          <span class="font-bold text-orange-500">×{combo}
            {#if comboLabel}
              <span class="text-[10px] bg-orange-200 text-orange-700 px-1 py-0.5 rounded ml-1">{comboLabel}</span>
            {/if}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-500">造成伤害</span>
          <span class="font-bold text-red-500">-{totalDamage} HP</span>
        </div>
        <div class="flex justify-between text-sm border-t border-yellow-200 pt-2">
          <span class="text-gray-700 font-semibold">能量奖励</span>
          <span class="font-bold text-green-600 text-lg">+{energyBonus}</span>
        </div>
      </div>

      <!-- Collect button -->
      <button
        onclick={handleCollect}
        class="w-full py-3 bg-gradient-to-r from-yellow-400 via-amber-400 to-orange-500
          text-white text-lg font-black rounded-xl
          hover:from-yellow-300 hover:via-amber-300 hover:to-orange-400
          active:scale-95 transition-all shadow-lg cursor-pointer animate-finishing-pulse">
        🎁 点击收集战利品！
      </button>
    </div>
  </div>
{/if}

<style>
  @keyframes loot-bg-flash {
    0% { opacity: 1; }
    100% { opacity: 0; }
  }
</style>
