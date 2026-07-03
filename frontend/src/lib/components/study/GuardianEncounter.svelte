<script lang="ts">
  import { getGuardianData, type GuardianData } from '$lib/types/adventure-map';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    visible = false,
    subject = 'math',
    combo = 0,
    answerResult = null as { isCorrect?: boolean } | null,
    sceneMode = false,
    onGuardianPurified = () => {},
    onEncounterEnd = () => {},
  }: {
    visible: boolean;
    subject: string;
    combo: number;
    answerResult: { isCorrect?: boolean } | null;
    sceneMode: boolean;
    onGuardianPurified?: () => void;
    onEncounterEnd?: () => void;
  } = $props();

  // ── Guardian data ──
  const guardian = $derived(getGuardianData(subject));

  // ── Encounter phases ──
  type EncounterPhase = 'idle' | 'greeting' | 'awaiting_answer' | 'purifying' | 'purified' | 'encouraging' | 'done';
  let phase = $state<EncounterPhase>('idle');
  let purifyProgress = $state(0);
  let showParticles = $state(false);
  let greetingText = $state('');
  let greetingIndex = $state(0);
  let mounted = $state(false);

  // ── Timers ──
  let greetingTimer: ReturnType<typeof setInterval> | null = null;
  let phaseTimer: ReturnType<typeof setTimeout> | null = null;
  let purifyTimer: ReturnType<typeof setInterval> | null = null;

  function cleanup() {
    if (greetingTimer) { clearInterval(greetingTimer); greetingTimer = null; }
    if (phaseTimer) { clearTimeout(phaseTimer); phaseTimer = null; }
    if (purifyTimer) { clearInterval(purifyTimer); purifyTimer = null; }
  }

  // ── Start encounter when visible ──
  $effect(() => {
    if (visible && !mounted) {
      mounted = true;
      startGreeting();
    }
    return () => cleanup();
  });

  function startGreeting() {
    phase = 'greeting';
    greetingText = '';
    greetingIndex = 0;
    soundManager.playBossTheme?.();

    // Typewriter greeting
    const fullText = guardian.greeting;
    greetingTimer = setInterval(() => {
      if (greetingIndex < fullText.length) {
        greetingIndex++;
        greetingText = fullText.slice(0, greetingIndex);
      } else {
        if (greetingTimer) { clearInterval(greetingTimer); greetingTimer = null; }
        // After greeting completes, transition to awaiting answer
        phaseTimer = setTimeout(() => {
          phase = 'awaiting_answer';
        }, 800);
      }
    }, 60);
  }

  // ── React to answer result ──
  $effect(() => {
    if (answerResult && phase === 'awaiting_answer') {
      if (answerResult.isCorrect) {
        startPurification();
      } else {
        startEncouragement();
      }
    }
  });

  // Also handle when answer arrives during greeting (fast answer)
  $effect(() => {
    if (answerResult && phase === 'greeting') {
      // Skip rest of greeting
      if (greetingTimer) { clearInterval(greetingTimer); greetingTimer = null; }
      greetingText = guardian.greeting;
      greetingIndex = guardian.greeting.length;

      // Short delay then process
      phaseTimer = setTimeout(() => {
        if (answerResult.isCorrect) {
          startPurification();
        } else {
          startEncouragement();
        }
      }, 500);
    }
  });

  function startPurification() {
    phase = 'purifying';
    purifyProgress = 0;
    soundManager.playCorrect?.();

    purifyTimer = setInterval(() => {
      purifyProgress += 3; // ~1.2 seconds to fill (100 / 3 * 36ms ≈ 1200ms)
      if (purifyProgress >= 100) {
        purifyProgress = 100;
        if (purifyTimer) { clearInterval(purifyTimer); purifyTimer = null; }
        completePurification();
      }
    }, 36);
  }

  function completePurification() {
    phase = 'purified';
    showParticles = true;
    soundManager.playComplete?.();

    phaseTimer = setTimeout(() => {
      onGuardianPurified();
      // Auto-dismiss after reward collected
      phaseTimer = setTimeout(() => {
        phase = 'done';
        mounted = false;
        onEncounterEnd();
      }, 1500);
    }, 2000);
  }

  function startEncouragement() {
    phase = 'encouraging';
    soundManager.playWrong?.();

    phaseTimer = setTimeout(() => {
      phase = 'done';
      mounted = false;
      onEncounterEnd();
    }, 2500);
  }
</script>

{#if visible && phase !== 'done'}
  <div class="fixed inset-0 z-50 flex items-center justify-center">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-gradient-to-b from-violet-900/60 to-indigo-900/80 backdrop-blur-md" />

    <!-- Main encounter card -->
    <div class="relative bg-white/95 backdrop-blur rounded-3xl shadow-2xl p-6 max-w-sm w-full mx-4
                {phase === 'greeting' ? 'animate-slide-up' : ''}">

      <!-- Guardian sprite area -->
      <div class="flex flex-col items-center mb-4">
        <!-- Guardian emoji with glow -->
        <div class="relative mb-2"
             class:animate-bounce-in={phase === 'greeting'}
             class:animate-purify-glow={phase === 'purifying' || phase === 'purified'}>
          <span class="text-7xl">{guardian.emoji}</span>
          {#if phase === 'purifying' || phase === 'purified'}
            <div class="absolute inset-0 rounded-full bg-white/30 animate-ping-slow" />
          {/if}
        </div>

        <!-- Guardian name + title -->
        <h2 class="text-xl font-black text-violet-800">{guardian.name}</h2>
        <p class="text-xs text-violet-400">{guardian.title}</p>
      </div>

      <!-- Purification progress ring -->
      {#if phase === 'purifying' || phase === 'purified'}
        <div class="flex justify-center mb-3">
          <div class="relative w-20 h-20">
            <svg class="w-20 h-20 -rotate-90" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="34" fill="none"
                      stroke="#e2e8f0" stroke-width="6" />
              <circle cx="40" cy="40" r="34" fill="none"
                      stroke="url(#purifyGrad)" stroke-width="6"
                      stroke-linecap="round"
                      stroke-dasharray={2 * Math.PI * 34}
                      stroke-dashoffset={2 * Math.PI * 34 * (1 - purifyProgress / 100)}
                      class="transition-all duration-100" />
            </svg>
            <div class="absolute inset-0 flex items-center justify-center">
              <span class="text-lg font-black text-violet-600">{purifyProgress}%</span>
            </div>
          </div>
          <svg width="0" height="0">
            <defs>
              <linearGradient id="purifyGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#a78bfa" />
                <stop offset="100%" stop-color="#fbbf24" />
              </linearGradient>
            </defs>
          </svg>
        </div>
      {/if}

      <!-- Dialogue text -->
      <div class="text-center min-h-[60px] flex items-center justify-center mb-3">
        {#if phase === 'greeting'}
          <p class="text-sm text-gray-700 leading-relaxed">
            {greetingText}<span class="animate-pulse">|</span>
          </p>
        {:else if phase === 'awaiting_answer'}
          <p class="text-sm text-violet-600 font-medium animate-pulse">
            请回答最后一道题...
          </p>
        {:else if phase === 'purifying'}
          <p class="text-sm text-violet-600 font-medium">
            知识之光正在净化黑暗...
          </p>
        {:else if phase === 'purified'}
          <p class="text-base font-bold text-amber-600">
            {guardian.purified}
          </p>
        {:else if phase === 'encouraging'}
          <p class="text-sm text-gray-600">
            {guardian.encouragement}
          </p>
        {/if}
      </div>

      <!-- Combo display (during purification) -->
      {#if phase === 'purified' && combo >= 2}
        <div class="text-center mb-2">
          <span class="text-amber-500 font-bold">
            🔥 {combo >= 5 ? 'MAX COMBO!' : combo >= 3 ? 'HOT STREAK!' : '连击'} ×{combo}
          </span>
        </div>
      {/if}

      <!-- Particle burst (on purified) -->
      {#if showParticles}
        <div class="absolute inset-0 pointer-events-none overflow-hidden rounded-3xl">
          {#each Array(20) as _, i}
            {@const angle = (i / 20) * 360}
            {@const dist = 60 + Math.random() * 100}
            {@const delay = Math.random() * 0.3}
            <div
              class="absolute top-1/2 left-1/2 w-3 h-3 rounded-full bg-amber-400 animate-particle-burst"
              style="--angle: {angle}deg; --dist: {dist}px; --delay: {delay}s;"
            />
          {/each}
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  @keyframes slideUp {
    0% { transform: translateY(40px); opacity: 0; }
    100% { transform: translateY(0); opacity: 1; }
  }
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    60% { transform: scale(1.1); }
    100% { transform: scale(1); opacity: 1; }
  }
  @keyframes purifyGlow {
    0%, 100% { filter: drop-shadow(0 0 8px rgba(168, 85, 247, 0.5)); }
    50% { filter: drop-shadow(0 0 20px rgba(250, 204, 21, 0.8)); }
  }
  @keyframes pingSlow {
    0% { transform: scale(1); opacity: 0.4; }
    50% { transform: scale(1.3); opacity: 0.1; }
    100% { transform: scale(1); opacity: 0.4; }
  }
  @keyframes particleBurst {
    0% {
      transform: translate(-50%, -50%) rotate(var(--angle)) translateY(0) scale(1);
      opacity: 1;
    }
    100% {
      transform: translate(-50%, -50%) rotate(var(--angle)) translateY(var(--dist)) scale(0);
      opacity: 0;
    }
  }
  :global(.animate-slide-up) { animation: slideUp 0.5s ease-out; }
  :global(.animate-bounce-in) { animation: bounceIn 0.5s ease-out; }
  :global(.animate-purify-glow) { animation: purifyGlow 1.5s ease-in-out infinite; }
  :global(.animate-ping-slow) { animation: pingSlow 2s ease-in-out infinite; }
  :global(.animate-particle-burst) {
    animation: particleBurst 1s ease-out var(--delay) forwards;
  }
</style>
