<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';

  let { combo = 0 }: { combo?: number } = $props();

  let prevCombo = $state(0);
  let pulseEffect = $state(false);

  const multiplier = $derived(
    combo >= 4 ? 2.0 : combo >= 2 ? 1.5 : 1.0
  );

  // Color escalation based on combo intensity
  const comboTheme = $derived.by(() => {
    if (combo >= 7) return { text: 'text-yellow-100', glow: 'drop-shadow(0 0 10px #fbbf24)', bar: 'from-yellow-200 via-yellow-400 to-orange-500', label: 'MAX COMBO!' };
    if (combo >= 5) return { text: 'text-orange-200', glow: 'drop-shadow(0 0 8px #fb923c)', bar: 'from-orange-300 via-orange-500 to-red-500', label: 'HOT STREAK!' };
    if (combo >= 4) return { text: 'text-orange-300', glow: 'drop-shadow(0 0 6px #ea580c)', bar: 'from-orange-400 to-red-500', label: '' };
    if (combo >= 2) return { text: 'text-orange-400', glow: 'drop-shadow(0 0 4px #f97316)', bar: 'from-amber-400 to-orange-500', label: '' };
    return { text: 'text-orange-500', glow: '', bar: '', label: '' };
  });

  $effect(() => {
    if (combo > prevCombo && combo >= 2) {
      pulseEffect = true;
      setTimeout(() => { pulseEffect = false; }, 400);
    } else if (combo === 0 && prevCombo >= 2) {
      // Combo broken — handled by visibility change (component hides)
      soundManager.playWrong();
    }
    prevCombo = combo;
  });

  let dynamicBorder = $derived(
    combo >= 7 ? 'border-yellow-300/70' :
    combo >= 4 ? 'border-orange-300/60' :
    'border-orange-400/50'
  );
</script>

{#if combo >= 2}
  <div class="flex items-center gap-2 animate-bounce-in">
    <!-- Flame glyphs with flicker animation -->
    <div class="flex items-center gap-0.5" style={comboTheme.glow}>
      {#each Array(Math.min(combo - 1, 5)) as _}
        <span class="text-base inline-block animate-flame-flicker" style="animation-delay: {Math.random() * 0.3}s">🔥</span>
      {/each}
    </div>

    <!-- Multiplier badge -->
    <div class="relative">
      <span
        class="font-black text-sm tabular-nums px-2 py-0.5 rounded-full border transition-all duration-300 {comboTheme.text} {dynamicBorder}"
        class:scale-125={pulseEffect}
      >
        ×{multiplier.toFixed(1)}
      </span>
      <!-- Glow ring -->
      <div class="absolute inset-0 rounded-full opacity-50 blur-sm -z-10 bg-orange-500"></div>
    </div>

    <!-- Hot streak label for high combos -->
    {#if comboTheme.label}
      <span class="text-xs font-bold bg-gradient-to-r {comboTheme.bar} bg-clip-text text-transparent animate-pulse">
        {comboTheme.label}
      </span>
    {/if}

    <!-- Star collection (combo >= 5) -->
    {#if combo >= 5}
      <div class="flex items-center gap-0.5 -ml-1">
        {#each Array(Math.min(combo - 4, 3)) as _, i}
          <span class="text-xs animate-star-pop" style="animation-delay: {i * 0.15}s;">⭐</span>
        {/each}
      </div>
    {/if}
  </div>
{/if}

<style>
  @keyframes flame-flicker {
    0%, 100% { transform: scaleY(1) translateY(0); opacity: 1; }
    25% { transform: scaleY(0.85) translateY(1px); opacity: 0.8; }
    50% { transform: scaleY(1.1) translateY(-1px); opacity: 0.9; }
    75% { transform: scaleY(0.9) translateY(0.5px); opacity: 0.85; }
  }
  :global(.animate-flame-flicker) {
    animation: flame-flicker 0.6s ease-in-out infinite;
  }
  @keyframes star-pop {
    0% { transform: scale(0) rotate(-30deg); opacity: 0; }
    60% { transform: scale(1.4) rotate(10deg); opacity: 1; }
    100% { transform: scale(1) rotate(0deg); opacity: 1; }
  }
  :global(.animate-star-pop) {
    animation: star-pop 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    opacity: 0;
  }
</style>
