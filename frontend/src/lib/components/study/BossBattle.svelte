<script lang="ts">
  import BossHealthBar from './BossHealthBar.svelte';
  import BossPhaseOverlay from './BossPhaseOverlay.svelte';
  import DamageNumber from './DamageNumber.svelte';
  import BossLootDrop from './BossLootDrop.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  /**
   * BossBattle — full boss encounter orchestrator.
   *
   * Phases: idle → charging → battle → victory | weakened → victory | escaped | defeated_player
   *
   * The parent MUST:
   *  1. Set visible=true when the last question is ready
   *  2. Call submitAnswer as normal, then pass answerResult + answerTimeMs
   *     to trigger the battle phase resolution
   *  3. Listen to callbacks for game state updates (HP, boss defeated, etc.)
   */

  type BossPhase = 'idle' | 'charging' | 'battle' | 'weakened' | 'victory' | 'escaped' | 'defeated_player';

  let {
    visible = false,
    subject = 'chinese',
    combo = 0,
    playerHp = 5,
    answerResult = null as { isCorrect?: boolean } | null,
    answerTimeMs = 0,
    onBossDefeated = () => {},
    onBossAttackPlayer = () => {},
    onBossEscaped = () => {}
  }: {
    visible?: boolean;
    subject?: string;
    combo?: number;
    playerHp?: number;
    answerResult?: { isCorrect?: boolean } | null;
    answerTimeMs?: number;
    onBossDefeated?: () => void;
    onBossAttackPlayer?: () => void;
    onBossEscaped?: () => void;
  } = $props();

  // ── Boss flavor data ──────────────────────────────
  const bossData: Record<string, { name: string; emoji: string; title: string }> = {
    chinese: { name: '黑暗诗魔', emoji: '🐉', title: '诗词大陆的混沌化身' },
    math: { name: '混沌几何体', emoji: '🔮', title: '智慧王国的远古守卫' },
    english: { name: '暗影巫师', emoji: '🧙', title: '魔法学院的堕落法师' }
  };
  const boss = $derived(bossData[subject] || bossData.chinese);

  // ── Boss battle state ─────────────────────────────
  const BOSS_MAX_HP = 100;
  const BASE_DAMAGE = 35;

  let phase = $state<BossPhase>('idle');
  let bossHp = $state(BOSS_MAX_HP);
  let chargeCountdown = $state(3);
  let finishingWindowActive = $state(false);
  let finishingTimeLeft = $state(2.0);
  let lastAnswer = $state<{ isCorrect?: boolean } | null>(null);

  // Damage display
  let showDamage = $state(false);
  let damageValue = $state(0);
  let damageIsPlayer = $state(false);
  let damageCritical = $state(false);

  // Loot
  let showLoot = $state(false);
  let totalDealt = $state(0);

  // Screen shake
  let screenShake = $state(false);

  // Mounted guard for timeout cleanup
  let mounted = $state(true);

  // Timers for cleanup
  let chargeTimer: ReturnType<typeof setTimeout> | null = null;
  let finishingTimer: ReturnType<typeof setInterval> | null = null;
  let finishingTimeout: ReturnType<typeof setTimeout> | null = null;
  let damageTimer: ReturnType<typeof setTimeout> | null = null;
  let victoryTimer: ReturnType<typeof setTimeout> | null = null;

  // ── Derived values ─────────────────────────────────
  const hpPercent = $derived(Math.max(0, (bossHp / BOSS_MAX_HP) * 100));

  // ── Damage calculation ─────────────────────────────
  function calculateDamage(answerTime: number, currentCombo: number): number {
    const comboMultiplier = currentCombo >= 4 ? 2.0 : currentCombo >= 2 ? 1.5 : 1.0;
    const timeSec = Math.max(answerTime, 500) / 1000;
    const speedBonus = timeSec <= 3 ? 1.5 : timeSec <= 5 ? 1.2 : 1.0;
    return Math.round(BASE_DAMAGE * comboMultiplier * speedBonus);
  }

  // ── Phase: IDLE → Charging ─────────────────────────
  $effect(() => {
    if (visible && phase === 'idle') {
      startCharging();
    }
  });

  function startCharging() {
    if (!mounted) return;
    phase = 'charging';
    chargeCountdown = 3;
    soundManager.playBossChargeUp();

    const tick = () => {
      if (!mounted) return;
      chargeCountdown--;
      if (chargeCountdown > 0) {
        chargeTimer = setTimeout(tick, 1000);
      } else {
        // Transition to battle
        phase = 'battle';
        soundManager.playBossPhaseChange();
      }
    };
    chargeTimer = setTimeout(tick, 1000);
  }

  // ── Phase: Process answer result ───────────────────
  $effect(() => {
    if (!answerResult || phase !== 'battle') return;
    lastAnswer = answerResult;
    resolveBattle(answerResult);
  });

  function resolveBattle(result: { isCorrect?: boolean }) {
    if (!mounted) return;

    if (result.isCorrect) {
      // Player attacks boss
      const damage = calculateDamage(answerTimeMs, combo);
      totalDealt = damage;
      bossHp = Math.max(0, bossHp - damage);
      damageValue = damage;
      damageIsPlayer = false;
      damageCritical = damage >= 100;
      showDamage = true;
      damageTimer = setTimeout(() => { showDamage = false; }, 1600);

      soundManager.playCorrect(combo);

      if (bossHp <= 0) {
        // VICTORY!
        victoryTimer = setTimeout(() => {
          phase = 'victory';
          showLoot = true;
          soundManager.playBossShatter();
        }, 600);
      } else if (bossHp <= 30) {
        // Weakened phase
        phase = 'weakened';
        startFinishingWindow();
        soundManager.playBossPhaseChange();
      } else {
        // Boss escapes — survived with > 30 HP
        phase = 'escaped';
        soundManager.playBossAttack();
        onBossEscaped();
      }
    } else {
      // Boss attacks player
      damageValue = 1;
      damageIsPlayer = true;
      damageCritical = false;
      showDamage = true;
      damageTimer = setTimeout(() => { showDamage = false; }, 1600);

      screenShake = true;
      setTimeout(() => { screenShake = false; }, 600);

      soundManager.playBossAttack();
      phase = 'defeated_player';
      onBossAttackPlayer();
    }
  }

  // ── Phase: Finishing window ────────────────────────
  function startFinishingWindow() {
    if (!mounted) return;
    finishingWindowActive = true;
    finishingTimeLeft = 2.0;

    finishingTimer = setInterval(() => {
      if (!mounted || !finishingWindowActive) return;
      finishingTimeLeft = Math.max(0, finishingTimeLeft - 0.05);
    }, 50);

    finishingTimeout = setTimeout(() => {
      if (!mounted) return;
      if (finishingWindowActive && phase === 'weakened') {
        // Player missed the finishing window
        finishingWindowActive = false;
        phase = 'escaped';
        soundManager.playBossAttack();
        onBossEscaped();
      }
      cleanupFinishing();
    }, 2100); // slightly more than 2s to allow for latency
  }

  function handleFinishingBlow() {
    if (!mounted || !finishingWindowActive) return;
    finishingWindowActive = false;
    cleanupFinishing();

    // Finishing blow deals remaining HP
    bossHp = 0;
    totalDealt = BOSS_MAX_HP;
    phase = 'victory';
    showLoot = true;
    soundManager.playBossShatter();
  }

  function cleanupFinishing() {
    if (finishingTimer) { clearInterval(finishingTimer); finishingTimer = null; }
    if (finishingTimeout) { clearTimeout(finishingTimeout); finishingTimeout = null; }
  }

  // ── Callbacks ──────────────────────────────────────
  function handleCollectLoot() {
    showLoot = false;
    onBossDefeated();
  }

  // ── Cleanup on unmount ─────────────────────────────
  $effect(() => {
    return () => {
      mounted = false;
      if (chargeTimer) clearTimeout(chargeTimer);
      cleanupFinishing();
      if (damageTimer) clearTimeout(damageTimer);
      if (victoryTimer) clearTimeout(victoryTimer);
    };
  });
</script>

{#if visible}
  <div class="mt-3" class:animate-shake-screen={screenShake}>
    <!-- Boss health bar -->
    <BossHealthBar
      {bossHp}
      bossMaxHp={BOSS_MAX_HP}
      bossName={boss.name}
      bossEmoji={boss.emoji}
      bossTitle={boss.title}
      {phase}
      {subject}
    />

    <!-- Phase overlay (charge countdown, finishing blow UI, victory flash) -->
    <BossPhaseOverlay
      {phase}
      {chargeCountdown}
      {finishingTimeLeft}
      bossName={boss.name}
      onFinishingBlow={handleFinishingBlow}
    />

    <!-- Floating damage number -->
    {#if showDamage}
      <DamageNumber
        value={damageValue}
        isPlayerDamage={damageIsPlayer}
        critical={damageCritical}
      />
    {/if}

    <!-- Loot drop -->
    {#if showLoot}
      <BossLootDrop
        show={true}
        bossName={boss.name}
        {combo}
        {subject}
        totalDamage={totalDealt}
        energyBonus={20}
        onCollect={handleCollectLoot}
      />
    {/if}
  </div>
{/if}
