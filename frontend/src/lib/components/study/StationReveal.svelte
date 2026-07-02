<script lang="ts">
  import { getStationTheme, getGuardianData, type StationType } from '$lib/types/adventure-map';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    stationType = 'study' as StationType,
    subject = 'math',
    visible = false,
    onComplete = () => {},
  }: {
    stationType: StationType;
    subject: string;
    visible: boolean;
    onComplete?: () => void;
  } = $props();

  // ── Animation phases ──
  let phase = $state<'entering' | 'display' | 'exiting' | 'done'>('done');
  let showContent = $state(false);

  const theme = $derived(getStationTheme(stationType));
  const guardian = $derived(stationType === 'guardian' ? getGuardianData(subject) : null);

  const description = $derived(
    stationType === 'study' ? '回答问题，积攒能量！'
    : stationType === 'treasure' ? '发现宝箱！答对获得额外积分奖励！'
    : stationType === 'rest' ? '休息片刻，补充能量～'
    : `守护者 ${guardian?.name ?? ''} 在等待你的挑战！`
  );

  const accentEmoji = $derived(
    stationType === 'study' ? '✨'
    : stationType === 'treasure' ? '🎉'
    : stationType === 'rest' ? '😌'
    : '⚡'
  );

  // ── Trigger animation when visible changes ──
  $effect(() => {
    if (visible && phase === 'done') {
      phase = 'entering';
      showContent = false;

      // Play station sound
      if (stationType === 'treasure') {
        soundManager.playCoinDrop?.();
      } else if (stationType === 'guardian') {
        soundManager.playBossTheme?.();
      }

      // Phase: entering → display
      setTimeout(() => {
        phase = 'display';
        showContent = true;
      }, 350);

      // Phase: display → exiting (rest stays longer)
      const displayDuration = stationType === 'rest' ? 2000 : 700;
      setTimeout(() => {
        phase = 'exiting';
        showContent = false;
      }, 350 + displayDuration);

      // Phase: exiting → done
      setTimeout(() => {
        phase = 'done';
        onComplete();
      }, 350 + displayDuration + 250);
    }
  });

  const containerClass = $derived(
    phase === 'done' ? 'opacity-0 pointer-events-none'
    : phase === 'exiting' ? 'opacity-0 transition-opacity duration-250'
    : 'opacity-100 transition-opacity duration-300'
  );
</script>

{#if phase !== 'done'}
  <div class="fixed inset-0 z-50 flex items-center justify-center {containerClass}">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" />

    <!-- Card -->
    <div class="relative bg-white rounded-3xl shadow-2xl p-8 max-w-xs w-full mx-4 text-center
                {phase === 'entering' ? 'scale-75' : 'scale-100'}
                transition-transform duration-300 ease-out">
      <!-- Station emoji -->
      <div class="text-6xl mb-3 animate-bounce-in">
        {theme.emoji}
      </div>

      <!-- Station name -->
      <h2 class="text-2xl font-black mb-2" style="color: #1e293b;">
        {theme.name}
      </h2>

      <!-- Accent emoji -->
      <p class="text-3xl mb-2">{accentEmoji}</p>

      <!-- Description -->
      {#if showContent}
        <p class="text-sm text-gray-500 animate-fade-in">
          {description}
        </p>
      {/if}

      <!-- Guardian special: name + title -->
      {#if stationType === 'guardian' && guardian && showContent}
        <div class="mt-3 pt-3 border-t border-gray-100 animate-fade-in">
          <p class="text-lg font-bold text-violet-700">{guardian.emoji} {guardian.name}</p>
          <p class="text-xs text-violet-400">{guardian.title}</p>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    60% { transform: scale(1.1); }
    100% { transform: scale(1); opacity: 1; }
  }
  @keyframes fadeIn {
    0% { opacity: 0; transform: translateY(8px); }
    100% { opacity: 1; transform: translateY(0); }
  }
  :global(.animate-bounce-in) {
    animation: bounceIn 0.4s ease-out;
  }
  :global(.animate-fade-in) {
    animation: fadeIn 0.3s ease-out;
  }
</style>
