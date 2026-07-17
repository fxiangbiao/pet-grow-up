<script lang="ts">
  interface Props { animation: string; autoplay?: boolean; }
  let { animation, autoplay = true }: Props = $props();
  let isPlaying = $state(autoplay);
  let animationKey = $state(0);
  function replay() { isPlaying = false; animationKey++; setTimeout(() => { isPlaying = true; }, 50); }
</script>

<div class="chinese-animation rounded-xl bg-gradient-to-br from-red-50 to-amber-100 p-4 relative overflow-hidden" key={animationKey}>
  {#if isPlaying}
    {#if animation === 'char_split'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-red-600 font-medium">Character Building</p>
        <div class="flex items-center gap-3 text-4xl font-bold">
          <span class="text-red-500 animate-slide-left">亲</span>
          <span class="text-gray-400 animate-pulse">+</span>
          <span class="text-amber-600 animate-slide-right">木</span>
          <span class="text-gray-400">=</span>
          <span class="text-green-600 animate-pop text-5xl">休</span>
        </div>
        <p class="text-sm text-gray-600 mt-2">A person leaning against a tree = rest</p>
      </div>
    {:else if animation === 'pinyin_tones'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-red-600 font-medium">Pinyin Tones</p>
        <div class="flex gap-4 mt-2">
          {#each [{t: 'mā', n: '1st', c: 'text-red-500'}, {t: 'mí', n: '2nd', c: 'text-orange-500'}, {t: 'mǐ', n: '3rd', c: 'text-yellow-500'}, {t: 'mà', n: '4th', c: 'text-green-500'}] as item, i}
            <div class="flex flex-col items-center animate-bounce" style="animation-delay: {i * 0.2}s">
              <span class="text-2xl font-bold {item.c}">{item.t}</span>
              <span class="text-xs text-gray-500">{item.n}</span>
            </div>
          {/each}
        </div>
      </div>
    {:else if animation === 'stroke_order'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-red-600 font-medium">Stroke Order</p>
        <div class="relative w-32 h-32 bg-white rounded-lg border-2 border-red-200">
          <div class="absolute inset-0 flex items-center justify-center">
            <span class="text-6xl text-gray-200">大</span>
          </div>
          <svg class="absolute inset-0 w-full h-full" viewBox="0 0 100 100">
            <line x1="20" y1="50" x2="80" y2="50" stroke="#ef4444" stroke-width="3" class="animate-stroke-1"/>
            <line x1="50" y1="20" x2="50" y2="80" stroke="#ef4444" stroke-width="3" class="animate-stroke-2"/>
            <line x1="50" y1="50" x2="20" y2="80" stroke="#ef4444" stroke-width="3" class="animate-stroke-3"/>
            <line x1="50" y1="50" x2="80" y2="80" stroke="#ef4444" stroke-width="3" class="animate-stroke-4"/>
          </svg>
        </div>
      </div>
    {:else}
      <div class="flex flex-col items-center gap-2 text-gray-500">
        <span class="text-4xl">📝</span>
        <p class="text-sm">Animation: {animation}</p>
      </div>
    {/if}
  {/if}
  <button onclick={replay} class="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/80 hover:bg-white flex items-center justify-center text-gray-500 hover:text-red-600 transition shadow-sm" title="Replay">→</button>
</div>

<style>
  @keyframes slide-left { 0% { opacity: 0; transform: translateX(-30px); } 100% { opacity: 1; transform: translateX(0); } }
  @keyframes slide-right { 0% { opacity: 0; transform: translateX(30px); } 100% { opacity: 1; transform: translateX(0); } }
  @keyframes pop { 0% { transform: scale(0); } 70% { transform: scale(1.2); } 100% { transform: scale(1); } }
  @keyframes stroke-draw { 0% { stroke-dashoffset: 100; } 100% { stroke-dashoffset: 0; } }
  .animate-slide-left { animation: slide-left 0.6s ease-out forwards; }
  .animate-slide-right { animation: slide-right 0.6s ease-out 0.3s forwards; opacity: 0; }
  .animate-pop { animation: pop 0.5s ease-out 0.8s forwards; opacity: 0; }
  .animate-stroke-1 { stroke-dasharray: 100; stroke-dashoffset: 100; animation: stroke-draw 0.5s ease-out 0.2s forwards; }
  .animate-stroke-2 { stroke-dasharray: 100; stroke-dashoffset: 100; animation: stroke-draw 0.5s ease-out 0.7s forwards; }
  .animate-stroke-3 { stroke-dasharray: 100; stroke-dashoffset: 100; animation: stroke-draw 0.5s ease-out 1.2s forwards; }
  .animate-stroke-4 { stroke-dasharray: 100; stroke-dashoffset: 100; animation: stroke-draw 0.5s ease-out 1.7s forwards; }
</style>