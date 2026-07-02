<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    energy = 100,
    maxEnergy = 100,
    mood = 'idle' as 'idle' | 'happy' | 'excited' | 'hurt',
  }: {
    energy?: number;
    maxEnergy?: number;
    mood?: 'idle' | 'happy' | 'excited' | 'hurt';
  } = $props();

  let prevEnergy = $state(100);
  let flashRed = $state(false);
  let flashGreen = $state(false);

  const energyPercent = $derived(Math.max(0, Math.min(100, (energy / maxEnergy) * 100)));

  // Color based on energy level
  const barColor = $derived(
    flashRed ? 'bg-red-400'
    : energyPercent >= 60 ? 'bg-gradient-to-r from-emerald-400 to-green-500'
    : energyPercent >= 30 ? 'bg-gradient-to-r from-amber-400 to-yellow-500'
    : 'bg-gradient-to-r from-orange-400 to-red-400'
  );

  const glowColor = $derived(
    flashRed ? 'drop-shadow(0 0 6px rgba(248,113,113,0.6))'
    : energyPercent >= 60 ? 'drop-shadow(0 0 6px rgba(52,211,153,0.5))'
    : energyPercent >= 30 ? 'drop-shadow(0 0 6px rgba(251,191,36,0.5))'
    : 'drop-shadow(0 0 6px rgba(248,113,113,0.4))'
  );

  const statusEmoji = $derived(
    energyPercent >= 80 ? '⚡'
    : energyPercent >= 50 ? '✨'
    : energyPercent >= 20 ? '🔋'
    : '🪫'
  );

  $effect(() => {
    if (energy < prevEnergy) {
      // Energy decreased — flash red briefly (no actual penalty — just visual feedback)
      flashRed = true;
      soundManager.playWrong?.();
      setTimeout(() => { flashRed = false; }, 400);
    } else if (energy > prevEnergy) {
      // Energy increased — flash green
      flashGreen = true;
      setTimeout(() => { flashGreen = false; }, 500);
    }
    prevEnergy = energy;
  });
</script>

<div class="flex items-center gap-2 select-none" role="status" aria-label={`能量: ${energyPercent.toFixed(0)}%`}>
  <span class="text-lg">{statusEmoji}</span>

  <!-- Energy bar container -->
  <div class="relative w-28 h-5 bg-gray-200 rounded-full overflow-hidden shadow-inner">
    <!-- Fill -->
    <div
      class="absolute inset-y-0 left-0 rounded-full transition-all duration-500 ease-out {barColor}"
      style="width: {energyPercent}%; {glowColor};"
    />

    <!-- Shine overlay -->
    <div class="absolute inset-0 rounded-full bg-gradient-to-b from-white/30 to-transparent pointer-events-none" />

    <!-- Flash overlay on gain -->
    {#if flashGreen}
      <div class="absolute inset-0 rounded-full bg-green-200/60 animate-flash-fade pointer-events-none" />
    {/if}
  </div>

  <!-- Percentage label -->
  <span class="text-xs font-bold text-gray-500 tabular-nums min-w-[2.5rem]">
    {energyPercent.toFixed(0)}%
  </span>

  <!-- Mood indicator -->
  {#if mood === 'excited'}
    <span class="text-sm animate-bounce">💫</span>
  {:else if mood === 'hurt'}
    <span class="text-sm opacity-60">😅</span>
  {/if}
</div>

<style>
  @keyframes flashFade {
    0% { opacity: 1; }
    100% { opacity: 0; }
  }
  :global(.animate-flash-fade) {
    animation: flashFade 0.5s ease-out forwards;
  }
</style>
