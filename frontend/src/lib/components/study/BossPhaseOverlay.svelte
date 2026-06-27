<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    phase = 'idle',
    chargeCountdown = 3,
    finishingTimeLeft = 2.0,
    bossName = '',
    onFinishingBlow = () => {}
  }: {
    phase?: string;
    chargeCountdown?: number;
    finishingTimeLeft?: number;
    bossName?: string;
    onFinishingBlow?: () => void;
  } = $props();

  let finishingMissed = $state(false);
  let finishingSuccess = $state(false);

  // Handle finishing blow attempt
  function handleFinishingBlow() {
    if (finishingSuccess || finishingMissed) return;
    finishingSuccess = true;
    soundManager.playBossPhaseChange();
    onFinishingBlow();
  }

  // Track when phase changes away from 'weakened'
  let wasWeakened = $state(false);
  $effect(() => {
    if (phase === 'weakened' && !wasWeakened) {
      wasWeakened = true;
      finishingMissed = false;
      finishingSuccess = false;
    }
    if (phase !== 'weakened') {
      wasWeakened = false;
      if (phase === 'escaped') {
        finishingMissed = true;
      }
    }
  });
</script>

{#if phase === 'charging'}
  <div class="fixed inset-0 z-40 flex items-center justify-center pointer-events-none">
    <div class="text-center">
      <!-- Countdown number -->
      {#key chargeCountdown}
        <div class="text-8xl font-black text-red-500 animate-bounce-in tabular-nums"
          style="text-shadow: 0 0 40px rgba(239,68,68,0.5);">
          {chargeCountdown}
        </div>
      {/key}
      <div class="text-xl font-bold text-red-600 mt-2 animate-pulse">
        ⚠️ {bossName} 正在蓄力！
      </div>
    </div>
  </div>

  <!-- Red vignette overlay -->
  <div class="fixed inset-0 z-30 pointer-events-none transition-opacity duration-1000"
    style="background: radial-gradient(ellipse at center, transparent 60%, rgba(239,68,68,0.15) 100%);">
  </div>

{:else if phase === 'battle'}
  <!-- Brief "Attack!" flash -->
  <div class="fixed inset-0 z-30 flex items-center justify-center pointer-events-none animate-slide-up"
    style="animation-duration: 0.6s;">
    <div class="text-4xl font-black text-white animate-bounce-in"
      style="text-shadow: 0 0 30px rgba(239,68,68,0.8); animation-duration: 0.6s;">
      ⚔️ 进攻！
    </div>
  </div>

{:else if phase === 'weakened'}
  <div class="fixed inset-0 z-40 flex flex-col items-center justify-center pointer-events-none">
    <!-- Weak pulse vignette -->
    <div class="absolute inset-0 bg-yellow-400/10 animate-pulse"></div>

    <!-- Message -->
    <div class="text-center mb-6 animate-bounce-in">
      <div class="text-5xl mb-2">💢</div>
      <div class="text-2xl font-black text-yellow-500"
        style="text-shadow: 0 0 20px rgba(234,179,8,0.5);">
        BOSS 虚弱了！
      </div>
      <div class="text-lg font-bold text-yellow-600 mt-1">
        快给 {bossName} 最后一击！
      </div>
    </div>

    <!-- Finishing blow button -->
    {#if !finishingSuccess && !finishingMissed}
      <button
        onclick={handleFinishingBlow}
        class="pointer-events-auto px-12 py-5 bg-gradient-to-r from-yellow-400 via-orange-400 to-red-500
          text-white text-2xl font-black rounded-2xl animate-finishing-pulse
          hover:from-yellow-300 hover:via-orange-300 hover:to-red-400
          active:scale-95 transition-all shadow-2xl cursor-pointer"
        style="text-shadow: 0 2px 4px rgba(0,0,0,0.3);">
        ⚡ 终结一击！
      </button>
    {:else if finishingSuccess}
      <div class="text-3xl font-black text-green-500 animate-bounce-in">⚡ 终结成功！</div>
    {:else}
      <div class="text-2xl font-bold text-gray-400">太迟了…</div>
    {/if}

    <!-- Timer bar -->
    <div class="mt-4 w-48 h-2 bg-gray-300 rounded-full overflow-hidden pointer-events-auto">
      <div
        class="h-full bg-gradient-to-r from-yellow-400 to-red-500 rounded-full transition-all duration-100 ease-linear"
        style="width: {Math.max(0, (finishingTimeLeft / 2) * 100)}%"
      ></div>
    </div>
    <div class="text-xs text-gray-500 mt-1">{finishingTimeLeft.toFixed(1)}s</div>
  </div>

{:else if phase === 'victory'}
  <!-- Victory flash -->
  <div class="fixed inset-0 z-30 pointer-events-none"
    style="background: radial-gradient(circle at center, rgba(255,215,0,0.2) 0%, transparent 70%);
           animation: victory-flash 0.6s ease-out;">
  </div>

  <!-- Victory text that auto-fades -->
  <div class="fixed inset-0 z-35 flex items-center justify-center pointer-events-none">
    <div class="text-center animate-bounce-in">
      <div class="text-6xl">👑</div>
      <div class="text-3xl font-black text-yellow-500 mt-2"
        style="text-shadow: 0 0 30px rgba(255,215,0,0.6);">
        VICTORY！
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes victory-flash {
    0% { opacity: 1; }
    100% { opacity: 0; }
  }
</style>
