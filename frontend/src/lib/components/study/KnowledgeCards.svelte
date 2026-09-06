<script lang="ts">
  import type { TeachingCard } from '$lib/api/study';
  import MathAnimation from './animations/MathAnimation.svelte';
  import ChineseAnimation from './animations/ChineseAnimation.svelte';
  import EnglishAnimation from './animations/EnglishAnimation.svelte';

  interface Props {
    cards: TeachingCard[];
    onComplete: () => void;
  }

  let { cards, onComplete }: Props = $props();

  let currentIndex = $state(0);
  let viewedCards = $state<Set<number>>(new Set([0]));

  const currentCard = $derived(cards[currentIndex]);
  const isLastCard = $derived(currentIndex >= cards.length - 1);
  const allViewed = $derived(viewedCards.size >= cards.length);
  const progress = $derived(((currentIndex + 1) / cards.length) * 100);

  function goNext() {
    if (currentIndex < cards.length - 1) {
      currentIndex++;
      viewedCards.add(currentIndex);
    }
  }

  function goPrev() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }

  // Card type icons
  const typeIcons: Record<string, string> = {
    intro: '📖',
    concept: '💡',
    steps: '📋',
    example: '✏️',
    mnemonic: '🎵',
    quiz: '❓'
  };

  // Card type background gradients
  const typeGradients: Record<string, string> = {
    intro: 'from-blue-100 to-indigo-100',
    concept: 'from-yellow-100 to-orange-100',
    steps: 'from-green-100 to-emerald-100',
    example: 'from-purple-100 to-pink-100',
    mnemonic: 'from-cyan-100 to-teal-100',
    quiz: 'from-rose-100 to-red-100'
  };
</script>

<div class="knowledge-cards rounded-2xl border-2 border-white/50 bg-white shadow-lg overflow-hidden">
  <!-- Progress bar -->
  <div class="h-1.5 bg-gray-100">
    <div
      class="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-500"
      style="width: {progress}%"
    ></div>
  </div>

  <!-- Card content -->
  <div class="p-6 min-h-[320px] flex flex-col">
    <!-- Card header -->
    <div class="flex items-center gap-2 mb-4">
      <span class="text-2xl">{typeIcons[currentCard.type] || '📖'}</span>
      <span class="text-xs font-medium text-gray-400 uppercase tracking-wider">
        {currentCard.type}
      </span>
      <span class="text-xs text-gray-400 ml-auto">
        {currentIndex + 1} / {cards.length}
      </span>
    </div>

    <!-- Card body -->
    <div class="flex-1 flex flex-col">
      <h3 class="text-xl font-bold text-gray-800 mb-3">{currentCard.title}</h3>

      <!-- Content based on card type -->
      <div class="flex-1 rounded-xl p-4 bg-gradient-to-br {typeGradients[currentCard.type] || 'from-gray-100 to-gray-200'}">
        {#if currentCard.type === 'intro'}
          <!-- Story introduction -->
          <div class="flex flex-col items-center text-center">
            {#if currentCard.illustration}
              <div class="text-6xl mb-4">
                {currentCard.illustration === 'apple_tree' ? '🍎' :
                 currentCard.illustration === 'book' ? '📚' :
                 currentCard.illustration === 'star' ? '⭐' : '🌟'}
              </div>
            {/if}
            <p class="text-gray-700 leading-relaxed text-lg">{currentCard.content}</p>
          </div>

        {:else if currentCard.type === 'concept'}
          <!-- Concept explanation -->
          <div class="space-y-3">
            <p class="text-gray-700 leading-relaxed">{currentCard.content}</p>
            {#if currentCard.animation}
              <div class="mt-4 p-3 bg-white/60 rounded-lg text-center text-sm text-gray-500">
                🎬 动画演示: {currentCard.animation}
              </div>
            {/if}
          </div>

        {:else if currentCard.type === 'steps'}
          <!-- Step-by-step guide -->
          <div class="space-y-3">
            {#if currentCard.steps}
              {#each currentCard.steps as step, i}
                <div class="flex items-start gap-3">
                  <span class="flex-shrink-0 w-7 h-7 rounded-full bg-white/80 flex items-center justify-center text-sm font-bold text-gray-600 shadow-sm">
                    {i + 1}
                  </span>
                  <p class="text-gray-700 pt-1">{step}</p>
                </div>
              {/each}
            {/if}
          </div>

        {:else if currentCard.type === 'example'}
          <!-- Interactive example -->
          <div class="flex flex-col items-center text-center space-y-4">
            <p class="text-3xl font-bold text-gray-800">{currentCard.content}</p>
            {#if currentCard.interactive}
              <div class="mt-2 p-3 bg-white/60 rounded-lg text-sm text-gray-600">
                👆 动手试一试！
              </div>
            {/if}
          </div>

        {:else if currentCard.type === 'mnemonic'}
          <!-- Memory aid / song -->
          <div class="flex flex-col items-center text-center space-y-3">
            <div class="text-4xl mb-2">🎵</div>
            <p class="text-lg text-gray-700 leading-relaxed font-medium whitespace-pre-line">
              {currentCard.content}
            </p>
          </div>

        {:else if currentCard.type === 'quiz'}
          <!-- Mini quiz within card -->
          <div class="flex flex-col items-center text-center space-y-4">
            <p class="text-lg text-gray-700">{currentCard.content}</p>
            <div class="text-4xl">🤔</div>
          </div>

        {:else}
          <!-- Fallback -->
          <p class="text-gray-700">{currentCard.content}</p>
        {/if}
      </div>
    </div>

    <!-- Navigation -->
    <div class="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
      <button
        onclick={goPrev}
        disabled={currentIndex === 0}
        class="px-4 py-2 rounded-lg text-sm font-medium transition
          {currentIndex === 0 ? 'text-gray-300 cursor-not-allowed' : 'text-gray-600 hover:bg-gray-100'}"
      >
        ← 上一张
      </button>

      <!-- Dot indicators -->
      <div class="flex gap-1.5">
        {#each cards as _, i}
          <button
            onclick={() => { currentIndex = i; viewedCards.add(i); }}
            class="w-2 h-2 rounded-full transition-all
              {i === currentIndex ? 'bg-blue-500 w-4' : viewedCards.has(i) ? 'bg-blue-300' : 'bg-gray-300'}"
            aria-label="第{i + 1}张卡片"
          ></button>
        {/each}
      </div>

      {#if isLastCard}
        <button
          onclick={onComplete}
          class="px-5 py-2 rounded-lg text-sm font-bold text-white bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 shadow-md transition"
        >
          开始练习 →
        </button>
      {:else}
        <button
          onclick={goNext}
          class="px-4 py-2 rounded-lg text-sm font-medium text-white bg-blue-500 hover:bg-blue-600 transition"
        >
          下一张 →
        </button>
      {/if}
    </div>
  </div>
</div>
