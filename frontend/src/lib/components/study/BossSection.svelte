<script lang="ts">
  import ParticleEffect from '$lib/components/feedback/ParticleEffect.svelte';

  let {
    visible = false,
    bossDefeated = false,
    bossHp = 100,
    subject = 'chinese'
  }: {
    visible?: boolean;
    bossDefeated?: boolean;
    bossHp?: number;
    subject?: string;
  } = $props();

  const bossData: Record<string, { name: string; emoji: string; title: string }> = {
    chinese: { name: '黑暗诗魔', emoji: '🐉', title: '诗词大陆守护者' },
    math: { name: '混沌几何体', emoji: '🔮', title: '智慧王国守护者' },
    english: { name: '暗影巫师', emoji: '🧙', title: '魔法学院守护者' }
  };

  const boss = $derived(bossData[subject] || bossData.chinese);
  const hpPercent = $derived(Math.max(0, Math.min(100, bossHp)));

  let showDefeatParticles = $state(false);

  $effect(() => {
    if (bossDefeated && visible) {
      setTimeout(() => { showDefeatParticles = true; }, 400);
    } else {
      showDefeatParticles = false;
    }
  });
</script>

{#if visible}
  <div class="bg-gradient-to-r from-red-50 via-red-50 to-orange-50 border-2 border-red-300 rounded-xl p-4 mb-4"
       class:border-green-400={bossDefeated}
       class:from-green-50={bossDefeated}
       class:via-green-50={bossDefeated}
       class:to-green-50={bossDefeated}
       class:animate-pulse-glow={!bossDefeated}>
    <!-- Boss header -->
    <div class="flex items-center gap-3 mb-3">
      <div class="text-3xl animate-breathe" class:animate-celebration={bossDefeated}>
        {#if bossDefeated}
          💥
        {:else}
          {boss.emoji}
        {/if}
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2">
          <span class="text-xs font-bold uppercase tracking-wider text-red-400">Boss Encounter</span>
          <span class="text-xl">👑</span>
        </div>
        <div class="text-base font-bold text-red-700" class:text-green-600={bossDefeated}>
          {boss.name}
        </div>
        <div class="text-xs text-gray-500">{boss.title}</div>
      </div>
      <!-- Boss HP label -->
      <div class="text-right">
        <span class="text-2xl font-black text-red-500" class:text-green-500={bossDefeated}>
          {bossDefeated ? '0' : hpPercent}
        </span>
        <span class="text-xs text-gray-500 block">/ 100 HP</span>
      </div>
    </div>

    <!-- Boss HP bar -->
    <div class="h-4 bg-red-100 rounded-full overflow-hidden border border-red-200 relative"
         class:bg-green-100={bossDefeated}
         class:border-green-200={bossDefeated}>
      <div
        class="h-full rounded-full transition-all duration-1000 ease-out"
        class:bg-gradient-to-r={true}
        class:from-red-500={!bossDefeated && hpPercent > 30}
        class:via-red-400={!bossDefeated && hpPercent > 30}
        class:to-red-600={!bossDefeated && hpPercent > 30}
        class:from-yellow-400={!bossDefeated && hpPercent <= 30}
        class:via-orange-400={!bossDefeated && hpPercent <= 30}
        class:to-red-500={!bossDefeated && hpPercent <= 30}
        class:from-green-400={bossDefeated}
        class:to-emerald-500={bossDefeated}
        style="width: {hpPercent}%"
      ></div>
      <!-- HP bar shimmer overlay -->
      {#if !bossDefeated && hpPercent > 0}
        <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer"></div>
      {/if}
    </div>

    <!-- Status message -->
    <div class="mt-2 text-center">
      {#if bossDefeated}
        <div class="text-sm text-green-600 font-bold animate-bounce-in flex items-center justify-center gap-1">
          💥 Boss {boss.name} 被击败！
        </div>
        <div class="text-xs text-green-500 mt-1">
          ⚡ 额外 +20 能量奖励
        </div>
      {:else}
        <div class="text-xs text-red-500 font-medium">
          ⚠️ 击败 Boss 可获得额外能量奖励！答错会被反击 -2 ❤️
        </div>
      {/if}
    </div>
  </div>

  <!-- Defeat particles -->
  {#if showDefeatParticles}
    <ParticleEffect emojis={['💥', '✨', '⭐', '🌟', '⚡', '🔥']} count={16} spread={90} duration={2500} active={true} />
  {/if}
{/if}

<style>
  @keyframes shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(200%); }
  }
  :global(.animate-shimmer) {
    animation: shimmer 1.5s ease-in-out infinite;
  }
</style>
