<script lang="ts">
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import EnemySprite from './EnemySprite.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    totalQuestions = 5,
    currentIndex = 0,
    results = [] as Array<boolean | null>,
    species = null as SpiritSpecies | null,
    evolutionStage = 1,
    mood = 'idle' as 'idle' | 'happy' | 'excited' | 'hurt',
    subjectTheme = 'chinese'
  }: {
    totalQuestions?: number;
    currentIndex?: number;
    results?: Array<boolean | null>;
    species?: SpiritSpecies | null;
    evolutionStage?: number;
    mood?: 'idle' | 'happy' | 'excited' | 'hurt';
    subjectTheme?: string;
  } = $props();

  const themeColors: Record<string, string> = {
    chinese: 'bg-amber-400',
    math: 'bg-blue-400',
    english: 'bg-purple-400'
  };
  const pathColor = $derived(themeColors[subjectTheme] || 'bg-indigo-400');

  /** Pick a minion variant based on index for variety */
  function enemyVariant(i: number): number {
    return i % 3;
  }

  /** Determine enemy state for a given position */
  function enemyState(i: number, results: Array<boolean | null>, currentIndex: number): string {
    if (i < currentIndex) {
      return results[i] ? 'defeated' : 'idle'; // defeated if correct, still idle if wrong
    }
    if (i === currentIndex) return 'idle';
    return 'idle';
  }
</script>

<div class="flex items-center justify-center gap-1 py-3 overflow-x-auto">
  {#each Array(totalQuestions) as _, i}
    {#if i > 0}
      <div class="w-4 h-0.5 rounded {i <= currentIndex ? pathColor : 'bg-gray-200'}"></div>
    {/if}

    <div class="flex flex-col items-center gap-1">
      {#if i === currentIndex && species}
        <!-- Current node: Spirit vs Enemy -->
        <div class="flex items-center gap-0.5 -mt-5 transition-all duration-300">
          <SpiritAvatar {species} {evolutionStage} size="sm" {mood} />
          <span class="text-xs animate-pulse">⚔️</span>
          {#if i === totalQuestions - 1}
            <EnemySprite enemyType="boss" subject={subjectTheme} variant={0}
              state={enemyState(i, results, currentIndex)} size="sm" />
          {:else}
            <EnemySprite enemyType="minion" subject={subjectTheme} variant={enemyVariant(i)}
              state={enemyState(i, results, currentIndex)} size="sm" />
          {/if}
        </div>
      {:else if i < currentIndex}
        <!-- Completed node: defeated enemy or survived enemy -->
        {#if results[i]}
          <EnemySprite enemyType={i === totalQuestions - 1 ? 'boss' : 'minion'}
            subject={subjectTheme} variant={enemyVariant(i)} state="defeated" size="sm" />
        {:else}
          <span class="text-sm">❌</span>
        {/if}
      {:else if i === totalQuestions - 1}
        <!-- Boss node (future) -->
        <EnemySprite enemyType="boss" subject={subjectTheme} variant={0}
          state="idle" size="sm" />
      {:else}
        <!-- Future minion nodes -->
        <EnemySprite enemyType="minion" subject={subjectTheme} variant={enemyVariant(i)}
          state="idle" size="sm" />
      {/if}

      <!-- Node dot -->
      <div class="w-3 h-3 rounded-full {i === currentIndex ? pathColor + ' ring-2 ring-offset-1 animate-pulse' : i < currentIndex ? pathColor : 'bg-gray-200'}"></div>
    </div>
  {/each}
</div>
