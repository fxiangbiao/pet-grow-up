<script lang="ts">
  let {
    experience = 0,
    totalForNextStage = 500,
    stage = 1
  }: {
    experience?: number;
    totalForNextStage?: number;
    stage?: number;
  } = $props();

  const percent = $derived(
    totalForNextStage > 0
      ? Math.max(0, Math.min(100, (experience / totalForNextStage) * 100))
      : 100
  );

  const isMaxStage = $derived(totalForNextStage <= 0 || stage >= 3);
  const canEvolve = $derived(!isMaxStage && experience >= totalForNextStage);
</script>

<div class="w-full">
  <div class="flex justify-between items-center text-sm mb-1">
    <span class="text-amber-700 font-medium">
      {#if isMaxStage}
        ⭐ 满级
      {:else}
        ✨ 经验值
      {/if}
    </span>
    <span class="text-amber-600 text-xs">
      {#if isMaxStage}
        MAX
      {:else}
        {experience} / {totalForNextStage}
      {/if}
    </span>
  </div>
  <div class="w-full bg-amber-50 rounded-full h-3.5 overflow-hidden border border-amber-200 relative">
    <div
      class="h-3.5 rounded-full transition-all duration-1000 ease-out relative overflow-hidden"
      class:bg-gradient-to-r={!isMaxStage}
      class:from-amber-300={!isMaxStage}
      class:to-amber-500={!isMaxStage}
      class:from-amber-400={isMaxStage}
      class:to-yellow-500={isMaxStage}
      class:animate-pulse-slow={canEvolve}
      style="width: {percent}%"
    >
      <!-- Shimmer effect -->
      <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"></div>
    </div>
    {#if canEvolve}
      <div class="absolute inset-0 rounded-full border-2 border-amber-400 animate-ping opacity-30 pointer-events-none"></div>
    {/if}
  </div>
  {#if canEvolve}
    <div class="text-center text-xs text-amber-600 font-semibold mt-1 animate-bounce">
      🌟 可以进化了！
    </div>
  {/if}
</div>

<style>
  @keyframes shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }
  .animate-shimmer {
    animation: shimmer 2s ease-in-out infinite;
  }
  @keyframes pulse-slow {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.85; }
  }
  :global(.animate-pulse-slow) {
    animation: pulse-slow 1.5s ease-in-out infinite;
  }
</style>
