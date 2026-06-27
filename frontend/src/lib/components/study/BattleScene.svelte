<script lang="ts">
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import EnemySprite from './EnemySprite.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  /**
   * BattleScene — the combat view showing spirit vs enemy in a themed environment.
   * Replaces the text-heavy adventure path with an actual battle screen.
   */
  let {
    subject = 'chinese',
    species = null as SpiritSpecies | null,
    evolutionStage = 1,
    mood = 'idle' as 'idle' | 'happy' | 'excited' | 'hurt',
    currentIndex = 0,
    totalQuestions = 5,
    isBoss = false,
    bossHp = 100,
    bossMaxHp = 100,
    combo = 0,
    state = 'idle' as 'idle' | 'player_attack' | 'enemy_attack' | 'enemy_defeated' | 'boss_phase'
  }: {
    subject?: string;
    species?: SpiritSpecies | null;
    evolutionStage?: number;
    mood?: 'idle' | 'happy' | 'excited' | 'hurt';
    currentIndex?: number;
    totalQuestions?: number;
    isBoss?: boolean;
    bossHp?: number;
    bossMaxHp?: number;
    combo?: number;
    state?: string;
  } = $props();

  const sceneColors: Record<string, { sky: string; ground: string; groundLine: string; particle: string }> = {
    chinese: { sky: '#FFF8E7', ground: '#E8D5B0', groundLine: '#C4A97D', particle: 'rgba(139,69,19,0.15)' },
    math: { sky: '#F0F8FF', ground: '#C8E0F8', groundLine: '#90C0E0', particle: 'rgba(30,144,255,0.1)' },
    english: { sky: '#F8F0FF', ground: '#D8C8E8', groundLine: '#B8A0D0', particle: 'rgba(147,112,219,0.12)' }
  };
  const sc = $derived(sceneColors[subject] || sceneColors.chinese);

  const enemyVariant = $derived((currentIndex) % 3);

  const bossHpPercent = $derived(Math.max(0, (bossHp / bossMaxHp) * 100));

  // Spirit position animation
  const spiritClass = $derived(
    state === 'player_attack' ? 'translate-x-8' :
    state === 'enemy_attack' ? '-translate-x-2' : ''
  );
  const enemyClass = $derived(
    state === 'player_attack' ? '-translate-x-2 scale-95' :
    state === 'enemy_attack' ? 'translate-x-6' :
    state === 'enemy_defeated' ? 'opacity-20 scale-75' : ''
  );
</script>

<div class="relative w-full h-48 rounded-xl overflow-hidden border-2 {isBoss ? 'border-red-400' : 'border-gray-200'}"
  style="background: linear-gradient(180deg, {sc.sky} 0%, {sc.sky} 55%, {sc.ground} 55%, {sc.ground} 100%);">

  <!-- Sky particles -->
  {#each Array(subject === 'math' ? 3 : 4) as _, i}
    <div class="absolute" style="left: {10 + i * 25}%; top: {15 + (i % 3) * 15}%;">
      <div class="w-1.5 h-1.5 rounded-full animate-float"
        style="background: {sc.particle}; animation-delay: {i * 1.5}s; animation-duration: {3 + i}s;">
      </div>
    </div>
  {/each}

  <!-- Ground line (horizon) -->
  <div class="absolute left-0 right-0" style="top: 55%; height: 2px; background: {sc.groundLine}; opacity: 0.5;"></div>

  <!-- Ground decorations -->
  {#if subject === 'chinese'}
    <!-- Ink stones / grass tufts -->
    <div class="absolute" style="left: 15%; bottom: 20%; font-size: 1.5rem; opacity: 0.3;">🌿</div>
    <div class="absolute" style="left: 70%; bottom: 15%; font-size: 1.2rem; opacity: 0.25;">🪨</div>
  {:else if subject === 'math'}
    <!-- Geometric crystals -->
    <div class="absolute" style="left: 20%; bottom: 18%; font-size: 1.2rem; opacity: 0.3;">💠</div>
    <div class="absolute" style="left: 75%; bottom: 22%; font-size: 1rem; opacity: 0.25;">🔹</div>
  {:else}
    <!-- Magical mushrooms -->
    <div class="absolute" style="left: 12%; bottom: 18%; font-size: 1.2rem; opacity: 0.3;">🍄</div>
    <div class="absolute" style="left: 78%; bottom: 20%; font-size: 1rem; opacity: 0.25;">✨</div>
  {/if}

  <!-- Spirit (left side) -->
  <div class="absolute transition-all duration-300 {spiritClass}"
    style="left: 12%; bottom: 18%; transform: translateY(0);">
    {#if species}
      <SpiritAvatar {species} {evolutionStage} size="md" {mood} />
    {/if}
  </div>

  <!-- VS / Attack effects -->
  <div class="absolute left-1/2 -translate-x-1/2" style="top: 30%;">
    {#if state === 'player_attack'}
      <!-- Slash effect -->
      <div class="text-3xl animate-bounce-in" style="animation-duration: 0.3s;">⚡</div>
    {:else if state === 'enemy_attack'}
      <!-- Enemy attack effect -->
      <div class="text-3xl animate-bounce-in text-red-500" style="animation-duration: 0.3s;">💢</div>
    {:else if state === 'enemy_defeated'}
      <div class="text-2xl animate-boss-shatter">💥</div>
    {:else}
      <!-- Idle: show encounter number -->
      <div class="text-xs font-black text-gray-400 bg-white/50 rounded-full px-2 py-0.5 backdrop-blur-sm">
        ROUND {currentIndex + 1}/{totalQuestions}
      </div>
    {/if}
  </div>

  <!-- Combo indicator (player side) -->
  {#if combo >= 2}
    <div class="absolute animate-bounce-in" style="left: 28%; top: 28%;">
      <span class="text-xs font-black text-orange-500 bg-orange-100 rounded-full px-2 py-0.5">
        ×{combo}
      </span>
    </div>
  {/if}

  <!-- Enemy (right side) -->
  <div class="absolute transition-all duration-300 {enemyClass}"
    style="right: 12%; bottom: 18%;">
    <EnemySprite
      enemyType={isBoss ? 'boss' : 'minion'}
      {subject}
      variant={isBoss ? 0 : enemyVariant}
      state={state === 'enemy_defeated' ? 'defeated' : state === 'player_attack' ? 'hit' : 'idle'}
      size="md" />
  </div>

  <!-- Boss HP bar (only for boss encounters) -->
  {#if isBoss}
    <div class="absolute left-0 right-0 mx-auto" style="top: 8%; width: 70%;">
      <div class="w-full h-3 bg-gray-200/50 rounded-full overflow-hidden backdrop-blur-sm">
        <div class="h-full bg-gradient-to-r from-red-500 to-orange-500 rounded-full transition-all duration-700"
          style="width: {bossHpPercent}%; box-shadow: 0 0 8px rgba(239,68,68,0.4);">
        </div>
      </div>
      <div class="text-center text-[10px] font-bold text-red-500 mt-0.5">
        BOSS · {Math.max(0, bossHp)} / {bossMaxHp}
      </div>
    </div>
  {/if}

  <!-- State overlay flash -->
  {#if state === 'player_attack'}
    <div class="absolute inset-0 bg-white/20 animate-bounce-in pointer-events-none" style="animation-duration: 0.4s;"></div>
  {:else if state === 'enemy_attack'}
    <div class="absolute inset-0 bg-red-500/10 animate-shake pointer-events-none" style="animation-duration: 0.5s;"></div>
  {/if}
</div>
