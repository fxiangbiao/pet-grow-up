<script lang="ts">
  interface Props { animation: string; autoplay?: boolean; }
  let { animation, autoplay = true }: Props = $props();
  let isPlaying = $state(autoplay);
  let animationKey = $state(0);
  function replay() { isPlaying = false; animationKey++; setTimeout(() => { isPlaying = true; }, 50); }
</script>

<div class="english-animation rounded-xl bg-gradient-to-br from-purple-50 to-pink-100 p-4 relative overflow-hidden" key={animationKey}>
  {#if isPlaying}
    {#if animation === 'word_picture'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-purple-600 font-medium">Word-Picture Match</p>
        <div class="flex gap-4 mt-2">
          {#each [{w: 'Apple', e: '🍎'}, {w: 'Cat', e: '🐱'}, {w: 'Sun', e: '☀️'}] as item, i}
            <div class="flex flex-col items-center gap-1 animate-pop" style="animation-delay: {i * 0.3}s">
              <span class="text-4xl">{item.e}</span>
              <span class="text-sm font-medium text-purple-700 bg-purple-100 px-2 py-1 rounded">{item.w}</span>
            </div>
          {/each}
        </div>
      </div>
    {:else if animation === 'letter_sound'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-purple-600 font-medium">Letter Sounds</p>
        <div class="flex gap-3 mt-2">
          {#each ['A', 'E', 'I', 'O', 'U'] as vowel, i}
            <div class="w-12 h-12 rounded-full bg-gradient-to-br from-purple-200 to-pink-200 flex items-center justify-center text-xl font-bold text-purple-700 animate-bounce" style="animation-delay: {i * 0.15}s">
              {vowel}
            </div>
          {/each}
        </div>
        <p class="text-xs text-gray-500 mt-2">These are the 5 vowels!</p>
      </div>
    {:else if animation === 'sentence_puzzle'}
      <div class="flex flex-col items-center gap-4">
        <p class="text-sm text-purple-600 font-medium">Sentence Builder</p>
        <div class="flex gap-2 mt-2">
          <span class="px-3 py-2 bg-blue-100 rounded-lg text-blue-700 font-medium animate-slide-up" style="animation-delay: 0s">I</span>
          <span class="px-3 py-2 bg-green-100 rounded-lg text-green-700 font-medium animate-slide-up" style="animation-delay: 0.2s">like</span>
          <span class="px-3 py-2 bg-orange-100 rounded-lg text-orange-700 font-medium animate-slide-up" style="animation-delay: 0.4s">to</span>
          <span class="px-3 py-2 bg-purple-100 rounded-lg text-purple-700 font-medium animate-slide-up" style="animation-delay: 0.6s">read</span>
          <span class="text-2xl animate-pop" style="animation-delay: 1s">📖</span>
        </div>
      </div>
    {:else}
      <div class="flex flex-col items-center gap-2 text-gray-500">
        <span class="text-4xl">📚</span>
        <p class="text-sm">Animation: {animation}</p>
      </div>
    {/if}
  {/if}
  <button onclick={replay} class="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/80 hover:bg-white flex items-center justify-center text-gray-500 hover:text-purple-600 transition shadow-sm" title="Replay">➡</button>
</div>

<style>
  @keyframes pop { 0% { transform: scale(0); opacity: 0; } 70% { transform: scale(1.2); } 100% { transform: scale(1); opacity: 1; } }
  @keyframes slide-up { 0% { opacity: 0; transform: translateY(20px); } 100% { opacity: 1; transform: translateY(0); } }
  .animate-pop { animation: pop 0.4s ease-out forwards; opacity: 0; }
  .animate-slide-up { animation: slide-up 0.5s ease-out forwards; opacity: 0; }
</style>