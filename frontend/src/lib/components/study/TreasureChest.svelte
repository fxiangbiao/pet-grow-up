<script lang="ts">
  import ParticleEffect from '$lib/components/feedback/ParticleEffect.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  /**
   * Interactive treasure chest with click-to-open and click-to-collect mechanics.
   * Phases: appearing → waiting_for_click → opening → revealed → collected
   */
  let {
    tier = 'small',
    show = false,
    energyBonus = 5,
    subject = 'chinese',
    onCollected = () => {}
  }: {
    tier?: 'small' | 'big';
    show?: boolean;
    energyBonus?: number;
    subject?: string;
    onCollected?: () => void;
  } = $props();

  type ChestPhase = 'hidden' | 'appearing' | 'waiting' | 'opening' | 'revealed' | 'collected';

  let phase = $state<ChestPhase>('hidden');
  let clicked = $state(false);

  $effect(() => {
    if (show && phase === 'hidden') {
      phase = 'appearing';
      soundManager.playTreasure();
      // Auto-advance to waiting for click after appear animation
      setTimeout(() => { phase = 'waiting'; }, 400);
    }
    if (!show) {
      phase = 'hidden';
      clicked = false;
    }
  });

  function handleOpen() {
    if (phase !== 'waiting' || clicked) return;
    clicked = true;
    phase = 'opening';
    soundManager.playClick();
    soundManager.playTreasure();
    // Advance to revealed after open animation
    setTimeout(() => { phase = 'revealed'; }, 800);
  }

  function handleCollect() {
    if (phase !== 'revealed') return;
    phase = 'collected';
    soundManager.playClick();
    onCollected();
  }

  const chestEmoji = $derived(tier === 'big' ? '🏆' : '🎁');
  const chestLabel = $derived(tier === 'big' ? '大宝箱' : '宝箱');
  const hpRecovery = $derived(tier === 'big' ? 1 : 0);

  // Subject-themed chest visuals
  const subjectChest: Record<string, { openEmoji: string; glowColor: string; promptText: string }> = {
    chinese: { openEmoji: '📜', glowColor: 'rgba(255, 215, 0, 0.4)', promptText: '展开卷轴' },
    math: { openEmoji: '💎', glowColor: 'rgba(0, 206, 209, 0.4)', promptText: '解锁宝箱' },
    english: { openEmoji: '🔮', glowColor: 'rgba(255, 105, 180, 0.4)', promptText: '念出咒语' }
  };
  const theme = $derived(subjectChest[subject] || subjectChest.chinese);

  const isVisible = $derived(phase !== 'hidden');
</script>

{#if isVisible}
  <!-- Backdrop overlay -->
  <div class="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm transition-opacity duration-300"
    class:opacity-0={phase === 'appearing'}
    class:opacity-100={phase !== 'appearing'}
    onclick={phase === 'waiting' ? handleOpen : phase === 'revealed' ? handleCollect : undefined}
  ></div>

  <!-- Gold particles during reveal -->
  {#if phase === 'revealed' || phase === 'collected'}
    <ParticleEffect
      emojis={tier === 'big' ? ['🏆', '✨', '💎', '⭐', '💰'] : ['🪙', '✨', '💫', '⭐']}
      count={tier === 'big' ? 14 : 8}
      spread={80}
      duration={2200}
      active={true}
    />
  {/if}

  <div class="fixed inset-0 z-50 flex items-center justify-center"
    class:pointer-events-none={phase === 'appearing'}
    class:pointer-events-auto={phase !== 'appearing'}>

    <div class="text-center transition-all duration-500"
      class:opacity-0:scale-90={phase === 'appearing'}
      class:opacity-100:scale-100={phase !== 'appearing'}>

      <!-- Chest icon with glow -->
      <div class="relative inline-block">
        <!-- Glow ring -->
        <div class="absolute inset-0 rounded-full blur-xl transition-all duration-300"
          style="background: {theme.glowColor};
            transform: scale({phase === 'waiting' ? 1.6 : phase === 'opening' ? 2 : 1});">
        </div>

        <!-- Chest / Loot icon -->
        {#key phase}
          <button
            onclick={phase === 'waiting' ? handleOpen : phase === 'revealed' ? handleCollect : undefined}
            class="relative text-7xl transition-all duration-300 cursor-pointer block mx-auto
              {phase === 'waiting' ? 'animate-breathe hover:scale-110' : ''}
              {phase === 'opening' ? 'animate-bounce-in' : ''}"
            class:animate-bounce={phase === 'waiting'}
            aria-label={phase === 'waiting' ? `打开${chestLabel}` : phase === 'revealed' ? '收集奖励' : chestLabel}
          >
            {#if phase === 'revealed' || phase === 'collected'}
              {theme.openEmoji}
            {:else if phase === 'opening'}
              ✨
            {:else}
              {chestEmoji}
            {/if}
          </button>
        {/key}
      </div>

      <!-- Label and prompt -->
      <div class="mt-3 transition-all duration-300"
        class:opacity-0={phase === 'appearing'}
        class:opacity-100={phase !== 'appearing'}>

        {#if phase === 'waiting'}
          <div class="text-lg font-bold text-amber-600 animate-pulse">
            发现{chestLabel}！
          </div>
          <div class="text-sm text-amber-500 mt-1">
            👆 点击{theme.promptText}
          </div>

        {:else if phase === 'opening'}
          <div class="text-lg font-bold text-amber-600 animate-bounce-in">
            开启中...
          </div>

        {:else if phase === 'revealed'}
          <div class="bg-amber-50 border-2 border-amber-300 rounded-xl px-5 py-3 inline-block animate-slide-up shadow-lg">
            <div class="text-amber-700 font-bold text-lg">
              ⚡ +{energyBonus} 能量
            </div>
            {#if hpRecovery > 0}
              <div class="text-red-500 font-bold text-sm mt-1">
                ❤️ +{hpRecovery} 生命
              </div>
            {/if}
            <div class="text-xs text-amber-400 mt-2 animate-pulse">
              👆 点击收集
            </div>
          </div>

        {:else if phase === 'collected'}
          <div class="text-base font-bold text-green-600 animate-bounce-in">
            ✅ 已收集！
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}
