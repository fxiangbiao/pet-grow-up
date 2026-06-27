<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';

  let { correctAnswer = '', explanation = '', isBoss = false }: { correctAnswer?: string; explanation?: string; isBoss?: boolean } = $props();
  let shake = $state(false);
  let showParticles = $state(false);

  $effect(() => {
    soundManager.playWrong();
    shake = true;
    showParticles = true;
    const t = setTimeout(() => { shake = false; showParticles = false; }, 1800);
    return () => clearTimeout(t);
  });
</script>

<div class="relative overflow-hidden {shake ? 'animate-shake' : 'animate-slide-up'}">
  <!-- Red flash overlay on initial shake -->
  {#if shake}
    <div class="absolute inset-0 bg-red-200/30 pointer-events-none animate-flash"></div>
  {/if}

  <div class="bg-red-50 border-2 border-red-300 rounded-xl p-4 text-center relative {isBoss ? 'ring-2 ring-red-200' : ''}">
    {#if showParticles}
      <div class="absolute inset-0 pointer-events-none">
        {#each Array(8) as _, i}
          <div
            class="absolute text-red-400/60 text-sm animate-particle-down"
            style="left: {10 + Math.random() * 80}%; top: {5 + Math.random() * 20}%;
                   animation-delay: {i * 0.08}s; animation-duration: {0.6 + Math.random() * 0.4}s;"
          >✦</div>
        {/each}
      </div>
    {/if}

    {#if isBoss}
      <div class="absolute top-2 right-2 bg-red-100 text-red-700 text-xs font-bold px-2 py-0.5 rounded-full">
        💀 Boss 攻击 -2 HP
      </div>
    {/if}

    <p class="text-3xl mb-1">{isBoss ? '💀' : '❌'}</p>
    <p class="text-red-700 font-medium mb-2">{isBoss ? 'Boss 反击！' : '回答错误'}</p>
    {#if correctAnswer}
      <p class="text-sm text-gray-600">正确答案：<span class="font-medium text-green-600">{correctAnswer}</span></p>
    {/if}
    {#if explanation}
      <p class="text-sm text-gray-500 mt-1">{explanation}</p>
    {/if}
  </div>
</div>

<style>
  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    15% { transform: translateX(-8px); }
    30% { transform: translateX(8px); }
    45% { transform: translateX(-5px); }
    60% { transform: translateX(5px); }
    75% { transform: translateX(-2px); }
    90% { transform: translateX(2px); }
  }
  :global(.animate-shake) {
    animation: shake 0.5s ease-out;
  }
  @keyframes flash {
    0% { opacity: 0; }
    20% { opacity: 1; }
    100% { opacity: 0; }
  }
  :global(.animate-flash) {
    animation: flash 0.4s ease-out forwards;
  }
  @keyframes particle-down {
    0% { opacity: 0.6; transform: translateY(0) scale(0.5); }
    100% { opacity: 0; transform: translateY(50px) scale(1); }
  }
  :global(.animate-particle-down) {
    animation: particle-down 0.8s ease-out forwards;
  }
</style>
