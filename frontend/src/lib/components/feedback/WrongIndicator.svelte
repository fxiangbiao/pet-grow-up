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
    <div class="absolute inset-0 bg-amber-200/20 pointer-events-none animate-flash"></div>
  {/if}

  <div class="bg-amber-50 border-2 border-amber-300 rounded-xl p-4 text-center relative {isBoss ? 'ring-2 ring-amber-200' : ''}">
    {#if showParticles}
      <div class="absolute inset-0 pointer-events-none">
        {#each Array(6) as _, i}
          <div
            class="absolute text-amber-400/50 text-sm animate-particle-up"
            style="left: {10 + Math.random() * 80}%; top: {40 + Math.random() * 40}%;
                   animation-delay: {i * 0.1}s; animation-duration: {0.8 + Math.random() * 0.5}s;"
          >✨</div>
        {/each}
      </div>
    {/if}

    {#if isBoss}
      <div class="absolute top-2 right-2 bg-amber-100 text-amber-700 text-xs font-bold px-2 py-0.5 rounded-full">
        💪 Boss 题，再挑战！
      </div>
    {/if}

    <p class="text-3xl mb-1">{isBoss ? '🤗' : '💪'}</p>
    <p class="text-amber-700 font-medium mb-2">{isBoss ? '差一点就打败 Boss 了！' : '没关系，再试试～'}</p>
    <p class="text-xs text-amber-500 mb-1">🐱 宠物在为你加油！</p>
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
    20% { opacity: 0.6; }
    100% { opacity: 0; }
  }
  :global(.animate-flash) {
    animation: flash 0.4s ease-out forwards;
  }
  @keyframes particle-up {
    0% { opacity: 0.5; transform: translateY(0) scale(0.5); }
    100% { opacity: 0; transform: translateY(-40px) scale(1); }
  }
  :global(.animate-particle-up) {
    animation: particle-up 1s ease-out forwards;
  }
</style>
