<script lang="ts">
  interface Props { animation: string; autoplay?: boolean; }
  let { animation, autoplay = true }: Props = $props();
  let isPlaying = $state(autoplay);
  let animationKey = $state(0);
  function replay() { isPlaying = false; animationKey++; setTimeout(() => { isPlaying = true; }, 50); }
</script>

<div class="math-animation rounded-xl bg-gradient-to-br from-blue-50 to-indigo-100 p-4 relative overflow-hidden" key={animationKey}>
  {#if isPlaying}
    {#if animation === 'make_ten_demo'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-blue-600 font-medium">Make-Ten Method</p>
        <div class="flex items-center gap-2 text-3xl font-bold">
          <span class="text-blue-600 animate-bounce">8</span>
          <span class="text-gray-400">+</span>
          <span class="text-orange-500 animate-bounce" style="animation-delay: 0.2s">5</span>
          <span class="text-gray-400">=</span>
          <span class="text-green-600 animate-pulse">?</span>
        </div>
        <div class="flex items-center gap-3 mt-2">
          <div class="flex flex-col items-center">
            <span class="text-xs text-gray-500 mb-1">Split</span>
            <div class="flex gap-1">
              <span class="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 font-bold animate-slide-up">2</span>
              <span class="text-gray-400">+</span>
              <span class="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 font-bold animate-slide-up" style="animation-delay: 0.3s">3</span>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2 mt-2">
          <span class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xl">8</span>
          <span class="text-gray-400">+</span>
          <span class="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 font-bold text-xl animate-glow">2</span>
          <span class="text-gray-400">=</span>
          <span class="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600 font-bold text-2xl animate-pop">10</span>
        </div>
        <div class="flex items-center gap-2 mt-2">
          <span class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center text-green-600 font-bold text-xl">10</span>
          <span class="text-gray-400">+</span>
          <span class="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 font-bold text-xl">3</span>
          <span class="text-gray-400">=</span>
          <span class="w-14 h-14 rounded-full bg-purple-100 flex items-center justify-center text-purple-600 font-bold text-2xl animate-celebrate">13</span>
        </div>
      </div>
    {:else if animation === 'number_line'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-blue-600 font-medium">Number Line Jump</p>
        <div class="relative w-full h-20 mt-4">
          <div class="absolute top-1/2 left-0 right-0 h-1 bg-gray-300 rounded"></div>
          <div class="absolute top-1/2 left-0 right-0 flex justify-between px-2 -translate-y-1/2">
            {#each [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20] as num}
              <span class="text-xs text-gray-500 w-6 text-center">{num}</span>
            {/each}
          </div>
          <div class="absolute top-0 left-1/2 -translate-x-1/2 animate-jump">
            <span class="text-3xl">🐸</span>
          </div>
        </div>
        <p class="text-sm text-gray-600 mt-8">Start at 10, jump forward 3 → 13</p>
      </div>
    {:else if animation === 'shape_transform'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-blue-600 font-medium">Shape Recognition</p>
        <div class="flex gap-6 mt-2">
          <div class="w-16 h-16 rounded-full bg-red-200 border-2 border-red-400 animate-morph-1 flex items-center justify-center">
            <span class="text-xs text-red-600">Circle</span>
          </div>
          <div class="w-16 h-16 rounded-lg bg-blue-200 border-2 border-blue-400 animate-morph-2 flex items-center justify-center">
            <span class="text-xs text-blue-600">Square</span>
          </div>
          <div class="w-16 h-16 bg-green-200 border-2 border-green-400 animate-morph-3 flex items-center justify-center" style="clip-path: polygon(50% 0%, 0% 100%, 100% 100%);">
            <span class="text-xs text-green-600 mt-4">Triangle</span>
          </div>
        </div>
      </div>
    {:else if animation === 'split_combine'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-blue-600 font-medium">Number Split</p>
        <div class="text-4xl font-bold text-blue-600 animate-pulse">10</div>
        <div class="flex gap-4 mt-2">
          <div class="flex flex-col items-center gap-1">
            <span class="w-10 h-10 rounded-full bg-yellow-100 flex items-center justify-center text-yellow-700 font-bold animate-pop">1</span>
            <span class="text-gray-400">+</span>
            <span class="w-10 h-10 rounded-full bg-yellow-100 flex items-center justify-center text-yellow-700 font-bold animate-pop" style="animation-delay: 0.2s">9</span>
          </div>
          <div class="flex flex-col items-center gap-1">
            <span class="w-10 h-10 rounded-full bg-pink-100 flex items-center justify-center text-pink-700 font-bold animate-pop" style="animation-delay: 0.4s">2</span>
            <span class="text-gray-400">+</span>
            <span class="w-10 h-10 rounded-full bg-pink-100 flex items-center justify-center text-pink-700 font-bold animate-pop" style="animation-delay: 0.6s">8</span>
          </div>
          <div class="flex flex-col items-center gap-1">
            <span class="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 font-bold animate-pop" style="animation-delay: 0.8s">5</span>
            <span class="text-gray-400">+</span>
            <span class="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 font-bold animate-pop" style="animation-delay: 1s">5</span>
          </div>
        </div>
      </div>
    {:else}
      <div class="flex flex-col items-center gap-2 text-gray-500">
        <span class="text-4xl">🔢</span>
        <p class="text-sm">Animation: {animation}</p>
      </div>
    {/if}
  {/if}
  <button onclick={replay} class="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/80 hover:bg-white flex items-center justify-center text-gray-500 hover:text-blue-600 transition shadow-sm" title="Replay">→</button>
</div>

<style>
  @keyframes slide-up { 0% { opacity: 0; transform: translateY(20px); } 100% { opacity: 1; transform: translateY(0); } }
  @keyframes glow { 0%, 100% { box-shadow: 0 0 5px rgba(251, 146, 60, 0.3); } 50% { box-shadow: 0 0 20px rgba(251, 146, 60, 0.6); } }
  @keyframes pop { 0% { transform: scale(0); } 70% { transform: scale(1.2); } 100% { transform: scale(1); } }
  @keyframes celebrate { 0% { transform: scale(0) rotate(0deg); } 50% { transform: scale(1.3) rotate(10deg); } 100% { transform: scale(1) rotate(0deg); } }
  @keyframes jump { 0% { transform: translateX(-50%) translateY(0); } 25% { transform: translateX(-25%) translateY(-30px); } 50% { transform: translateX(0%) translateY(0); } 75% { transform: translateX(25%) translateY(-30px); } 100% { transform: translateX(50%) translateY(0); } }
  @keyframes morph-1 { 0%, 100% { transform: scale(1); } 50% { transform: scale(1.1); } }
  @keyframes morph-2 { 0%, 100% { transform: rotate(0deg); } 50% { transform: rotate(5deg); } }
  @keyframes morph-3 { 0%, 100% { opacity: 1; } 50% { opacity: 0.7; } }
  .animate-slide-up { animation: slide-up 0.5s ease-out forwards; }
  .animate-glow { animation: glow 1.5s ease-in-out infinite; }
  .animate-pop { animation: pop 0.4s ease-out forwards; }
  .animate-celebrate { animation: celebrate 0.6s ease-out forwards; }
  .animate-jump { animation: jump 2s ease-in-out infinite; }
  .animate-morph-1 { animation: morph-1 2s ease-in-out infinite; }
  .animate-morph-2 { animation: morph-2 2s ease-in-out infinite; }
  .animate-morph-3 { animation: morph-3 2s ease-in-out infinite; }
</style>