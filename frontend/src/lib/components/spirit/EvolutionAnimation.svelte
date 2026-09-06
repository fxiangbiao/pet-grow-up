<script lang="ts">
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    active = false,
    species,
    fromStage = 1,
    toStage = 2,
    oncomplete
  }: {
    active?: boolean;
    species: SpiritSpecies;
    fromStage?: number;
    toStage?: number;
    oncomplete?: () => void;
  } = $props();

  let phase = $state<'idle' | 'stars' | 'fadeout' | 'transform' | 'fadein' | 'celebrate' | 'done'>('idle');
  let elapsed = $state(0);

  $effect(() => {
    if (active && phase === 'idle') {
      phase = 'stars';
      elapsed = 0;
      runSequence();
    }
  });

  async function runSequence() {
    const steps: [typeof phase, number][] = [
      ['stars', 800],
      ['fadeout', 600],
      ['transform', 400],
      ['fadein', 600],
      ['celebrate', 1200],
      ['done', 0]
    ];

    for (const [p, delay] of steps) {
      phase = p;
      if (delay > 0) await new Promise(r => setTimeout(r, delay));
    }
    oncomplete?.();
  }

  // Star particles
  const stars = Array.from({ length: 12 }, (_, i) => ({
    angle: i * 30,
    delay: Math.random() * 0.5,
    size: 3 + Math.random() * 4
  }));

  // Celebration particles
  const confetti = Array.from({ length: 20 }, (_, i) => ({
    x: 50 + (Math.random() - 0.5) * 80,
    y: 50 + (Math.random() - 0.5) * 80,
    color: ['#FFD700', '#FF69B4', '#7C3AED', '#06B6D4', '#10B981'][i % 5],
    delay: Math.random() * 0.6,
    size: 4 + Math.random() * 6
  }));
</script>

{#if active && phase !== 'idle' && phase !== 'done'}
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
    <div class="relative w-64 h-64 flex items-center justify-center">
      <!-- Stars ring -->
      {#if phase === 'stars' || phase === 'fadeout'}
        {#each stars as star, i}
          <div
            class="absolute rounded-full bg-yellow-300"
            style="
              width: {star.size}px;
              height: {star.size}px;
              left: calc(50% + {60 * Math.cos((star.angle * Math.PI) / 180)}px);
              top: calc(50% + {60 * Math.sin((star.angle * Math.PI) / 180)}px);
              animation: starPulse 0.8s ease-in-out {star.delay}s infinite alternate;
              box-shadow: 0 0 8px rgba(253, 224, 71, 0.8);
            "
          ></div>
        {/each}
      {/if}

      <!-- Spirit (before: fading out) -->
      {#if phase === 'stars' || phase === 'fadeout'}
        <div
          class="text-6xl transition-all"
          class:opacity-0={phase === 'fadeout'}
          class:scale-50={phase === 'fadeout'}
          style="transition-duration: 600ms"
        >
          {species.spriteUrl ? '' : '🐾'}
        </div>
      {/if}

      <!-- Transform flash -->
      {#if phase === 'transform'}
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="w-32 h-32 rounded-full bg-white animate-flash"></div>
        </div>
      {/if}

      <!-- Spirit (after: fading in) -->
      {#if phase === 'fadein' || phase === 'celebrate'}
        <div
          class="text-7xl transition-all duration-700"
          class:opacity-100={phase === 'fadein' || phase === 'celebrate'}
          class:scale-110={phase === 'celebrate'}
        >
          {species.spriteUrl ? '' : '🐾'}
        </div>
      {/if}

      <!-- Celebration confetti -->
      {#if phase === 'celebrate'}
        {#each confetti as c, i}
          <div
            class="absolute rounded-full"
            style="
              width: {c.size}px;
              height: {c.size}px;
              background: {c.color};
              left: {c.x}%;
              top: {c.y}%;
              animation: confettiPop 1s ease-out {c.delay}s both;
            "
          ></div>
        {/each}

        <!-- Stage up text -->
        <div class="absolute -bottom-16 left-1/2 -translate-x-1/2 whitespace-nowrap">
          <div class="text-xl font-bold text-yellow-300 animate-bounce-in" style="text-shadow: 0 2px 8px rgba(0,0,0,0.5);">
            🌟 Stage {toStage} 进化成功！
          </div>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  @keyframes starPulse {
    0% { opacity: 0.3; transform: scale(0.5); }
    100% { opacity: 1; transform: scale(1.3); }
  }

  @keyframes flash {
    0% { opacity: 0; transform: scale(0.3); }
    50% { opacity: 1; transform: scale(1.5); }
    100% { opacity: 0; transform: scale(2); }
  }
  .animate-flash {
    animation: flash 0.4s ease-out;
  }

  @keyframes confettiPop {
    0% { opacity: 0; transform: scale(0) translateY(0); }
    50% { opacity: 1; transform: scale(1.2) translateY(-30px); }
    100% { opacity: 0; transform: scale(0.5) translateY(20px); }
  }

  @keyframes bounceIn {
    0% { opacity: 0; transform: translateX(-50%) scale(0.3); }
    60% { opacity: 1; transform: translateX(-50%) scale(1.1); }
    100% { transform: translateX(-50%) scale(1); }
  }
  .animate-bounce-in {
    animation: bounceIn 0.5s ease-out;
  }
</style>
