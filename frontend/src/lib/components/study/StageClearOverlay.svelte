<script lang="ts">
  import ParticleEffect from '$lib/components/feedback/ParticleEffect.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  /**
   * StageClearOverlay — dramatic level-clear celebration sequence.
   * Phases: flash → STAGE CLEAR text → spirit celebration → stats roll in → collect
   */
  let {
    show = false,
    subject = 'chinese',
    maxCombo = 0,
    bossDefeated = true,
    treasuresFound = 0,
    energyEarned = 0,
    onCollect = () => {}
  }: {
    show?: boolean;
    subject?: string;
    maxCombo?: number;
    bossDefeated?: boolean;
    treasuresFound?: number;
    energyEarned?: number;
    onCollect?: () => void;
  } = $props();

  let phase = $state<'idle' | 'flash' | 'title' | 'stats' | 'collect' | 'done'>('idle');
  let collected = $state(false);

  $effect(() => {
    if (show && phase === 'idle') {
      soundManager.playCelebrate();
      // Phase 1: white flash
      phase = 'flash';
      setTimeout(() => { phase = 'title'; }, 400);
      // Phase 2: stats
      setTimeout(() => { phase = 'stats'; }, 1600);
      // Phase 3: collect
      setTimeout(() => { phase = 'collect'; }, 2800);
    }
    if (!show) {
      phase = 'idle';
      collected = false;
    }
  });

  function handleCollect() {
    if (collected) return;
    collected = true;
    phase = 'done';
    soundManager.playClick();
    setTimeout(() => { onCollect(); }, 400);
  }

  const subjectName: Record<string, string> = {
    chinese: '诗词大陆', math: '智慧王国', english: '魔法学院'
  };
  const subjectEmoji: Record<string, string> = {
    chinese: '📜', math: '🔢', english: '🔤'
  };
</script>

{#if show && phase !== 'idle' && phase !== 'done'}
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div class="fixed inset-0 z-50 flex items-center justify-center"
    onclick={phase === 'collect' ? handleCollect : undefined}
    class:cursor-pointer={phase === 'collect'}
    role="button" tabindex="0" aria-label="Collect stage rewards"
    onkeydown={(e) => { if (e.key === 'Enter' && phase === 'collect') handleCollect(); }}>

    <!-- White flash -->
    {#if phase === 'flash'}
      <div class="absolute inset-0 bg-white animate-bounce-in" style="animation-duration: 0.5s;"></div>
    {/if}

    <!-- Stage Clear title -->
    {#if phase === 'title' || phase === 'stats' || phase === 'collect'}
      <div class="absolute inset-0"
        style="background: radial-gradient(circle, rgba(255,215,0,0.15) 0%, rgba(0,0,0,0.4) 100%);">
      </div>

      <!-- Victory particles -->
      <ParticleEffect
        emojis={['⭐','✨','🌟','🎉','💫','🏆','💎','🎊']}
        count={20} spread={100} duration={3500} active={true} />

      <div class="relative z-10 text-center">
        <!-- STAGE CLEAR! big text -->
        <div class="animate-bounce-in" class:animate-slide-up={phase !== 'title'}>
          <div class="text-6xl font-black text-yellow-400 mb-2"
            style="text-shadow: 0 0 40px rgba(255,215,0,0.6), 0 4px 8px rgba(0,0,0,0.3);">
            STAGE CLEAR!
          </div>
          <div class="text-xl font-bold text-white/90 mb-4">
            {subjectEmoji[subject]} {subjectName[subject]}
          </div>
        </div>

        <!-- Stats roll-in -->
        {#if phase === 'stats' || phase === 'collect'}
          <div class="animate-slide-up space-y-2 max-w-xs mx-auto">
            <div class="bg-white/15 backdrop-blur-sm rounded-xl px-5 py-2 text-white font-bold flex justify-between">
              <span>🔥 最高连击</span>
              <span class="text-yellow-300">×{maxCombo}</span>
            </div>
            <div class="bg-white/15 backdrop-blur-sm rounded-xl px-5 py-2 text-white font-bold flex justify-between">
              <span>{bossDefeated ? '👑 Boss' : '💀 Boss'}</span>
              <span class={bossDefeated ? 'text-green-300' : 'text-red-300'}>
                {bossDefeated ? '已击败' : '未击败'}
              </span>
            </div>
            <div class="bg-white/15 backdrop-blur-sm rounded-xl px-5 py-2 text-white font-bold flex justify-between">
              <span>🎁 宝箱</span>
              <span class="text-amber-300">{treasuresFound} 个</span>
            </div>
            <div class="bg-white/15 backdrop-blur-sm rounded-xl px-5 py-2 text-white font-bold flex justify-between">
              <span>⚡ 能量</span>
              <span class="text-yellow-300">+{energyEarned}</span>
            </div>
          </div>

          {#if phase === 'collect'}
            <div class="mt-6 animate-bounce-in">
              <button
                onclick={handleCollect}
                class="px-10 py-3 bg-gradient-to-r from-yellow-400 via-amber-400 to-orange-500
                  text-white text-xl font-black rounded-2xl shadow-2xl
                  hover:from-yellow-300 hover:to-orange-400 active:scale-95 transition-all
                  animate-finishing-pulse cursor-pointer">
                🎉 点击继续！
              </button>
            </div>
          {/if}
        {/if}
      </div>
    {/if}
  </div>
{/if}
