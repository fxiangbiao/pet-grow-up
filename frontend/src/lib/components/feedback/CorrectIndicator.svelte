<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';
  import { onMount } from 'svelte';

  let { show = true, combo = 0, isBoss = false }: { show?: boolean; combo?: number; isBoss?: boolean } = $props();

  let showParticles = $state(false);
  let emojis = $state<string[]>(['✦', '✦', '✦', '✦', '✦', '✦']);

  $effect(() => {
    if (show) {
      soundManager.playCorrect(combo);
      showParticles = true;
      // More festive particles at higher combos
      emojis = combo >= 3
        ? ['🌟', '✨', '⭐', '💫', '🔥', '✨']
        : combo >= 2
          ? ['✦', '🌟', '✦', '⭐', '✦', '✨']
          : ['✦', '✦', '✦', '✦', '✦', '✦'];
      const t = setTimeout(() => { showParticles = false; }, 2500);
      return () => clearTimeout(t);
    }
  });

  const bgClass = $derived(isBoss
    ? 'bg-yellow-50 border-yellow-400'
    : combo >= 3
      ? 'bg-green-50 border-emerald-400 ring-2 ring-emerald-200'
      : 'bg-green-50 border-green-200');
</script>

{#if show}
  <div class="{bgClass} border rounded-xl p-4 text-center animate-bounce-in relative overflow-hidden transition-all duration-300">
    <!-- Particle effects -->
    {#if showParticles}
      <div class="absolute inset-0 pointer-events-none">
        {#each emojis as emoji, i}
          <div
            class="absolute text-sm animate-particle-up"
            style="left: {10 + Math.random() * 80}%; bottom: {10 + Math.random() * 30}%;
                   animation-delay: {i * 0.07}s; animation-duration: {0.8 + Math.random() * 0.6}s;
                   opacity: 0.9;"
          >{emoji}</div>
        {/each}
      </div>
    {/if}

    <!-- Combo badge -->
    {#if combo >= 2}
      <div class="absolute top-2 right-2 bg-orange-100 text-orange-700 text-xs font-bold px-2 py-0.5 rounded-full animate-bounce-in">
        🔥 {combo}连击
      </div>
    {/if}

    <p class="text-3xl mb-1">{isBoss ? '👑' : '✅'}</p>
    <p class="text-green-700 font-medium">
      {isBoss ? 'Boss 击败！' : combo >= 3 ? '太棒了！' : '回答正确！'}
    </p>
    {#if combo >= 2}
      <p class="text-xs text-orange-500 font-medium mt-0.5 animate-slide-up">连击 x{combo}</p>
    {/if}
  </div>
{/if}

<style>
  @keyframes particle-up {
    0% { opacity: 1; transform: translateY(0) scale(0.5) rotate(0deg); }
    100% { opacity: 0; transform: translateY(-80px) scale(1.2) rotate(180deg); }
  }
  :global(.animate-particle-up) {
    animation: particle-up 1s ease-out forwards;
  }
</style>
