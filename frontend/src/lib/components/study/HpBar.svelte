<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    hp = 5,
    maxHp = 5
  }: {
    hp?: number;
    maxHp?: number;
  } = $props();

  // Track which heart just broke for animation
  let breakingIndex = $state(-1);
  let prevHp = $state(5);

  $effect(() => {
    if (hp < prevHp) {
      breakingIndex = hp;
      soundManager.playWrong();
      setTimeout(() => { breakingIndex = -1; }, 800);
    }
    prevHp = hp;
  });
</script>

<div class="flex items-center gap-1 select-none" role="status" aria-label={`HP: ${hp}/${maxHp}`}>
  {#each Array(maxHp) as _, i}
    {#if i === breakingIndex}
      <span class="text-2xl inline-block animate-heart-break">💔</span>
    {:else if i < hp}
      <span class="text-2xl inline-block filter drop-shadow-red transition-all duration-300">❤️</span>
    {:else}
      <span class="text-2xl inline-block opacity-30 grayscale transition-all duration-300">🖤</span>
    {/if}
  {/each}
  <span class="ml-2 text-xs font-bold text-gray-500 tabular-nums">
    {hp}/{maxHp}
  </span>
</div>

<style>
  @keyframes heart-break {
    0% { transform: scale(1); }
    15% { transform: scale(1.4); opacity: 1; filter: brightness(2); }
    30% { transform: scale(0.5); opacity: 0.9; }
    50% { transform: scale(1.1) rotate(-10deg); opacity: 0.7; }
    70% { transform: scale(0.4) rotate(15deg); opacity: 0.4; }
    85% { transform: scale(1.0) rotate(-5deg); opacity: 0.25; filter: grayscale(0.5); }
    100% { transform: scale(0.8) rotate(0deg); opacity: 0.3; filter: grayscale(1); }
  }
  :global(.animate-heart-break) {
    animation: heart-break 0.7s ease-out forwards;
  }
  :global(.drop-shadow-red) {
    filter: drop-shadow(0 0 4px rgba(239, 68, 68, 0.4));
  }
</style>
