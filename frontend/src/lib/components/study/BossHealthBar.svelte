<script lang="ts">
  import EnemySprite from './EnemySprite.svelte';

  let {
    bossHp = 100,
    bossMaxHp = 100,
    bossName = '',
    bossEmoji = '👹',
    bossTitle = '',
    phase = 'idle',
    subject = 'chinese'
  }: {
    bossHp?: number;
    bossMaxHp?: number;
    bossName?: string;
    bossEmoji?: string;
    bossTitle?: string;
    phase?: string;
    subject?: string;
  } = $props();

  const hpPercent = $derived(Math.max(0, Math.min(100, (bossHp / bossMaxHp) * 100)));
  const isDead = $derived(bossHp <= 0);
  const isLow = $derived(hpPercent <= 30 && hpPercent > 0);
  const isEscaped = $derived(phase === 'escaped');

  const barGradient = $derived(
    isDead ? 'from-green-400 to-emerald-500' :
    isLow ? 'from-yellow-400 to-orange-500' :
    'from-red-500 to-orange-600'
  );

  const barGlow = $derived(
    isDead ? 'shadow-[0_0_12px_rgba(52,211,153,0.6)]' :
    isLow ? 'shadow-[0_0_10px_rgba(251,191,36,0.6)]' :
    'shadow-[0_0_8px_rgba(239,68,68,0.6)]'
  );

  const emojiClass = $derived(
    isDead ? 'animate-boss-shatter' :
    isEscaped ? 'opacity-30 grayscale' :
    phase === 'charging' ? 'animate-boss-charge-pulse' :
    'animate-breathe'
  );

  const cardBorder = $derived(
    isDead ? 'border-green-400 bg-gradient-to-r from-green-50 to-emerald-50' :
    isEscaped ? 'border-gray-300 bg-gradient-to-r from-gray-50 to-gray-100' :
    phase === 'charging' ? 'border-red-500 bg-gradient-to-r from-red-50 to-orange-50' :
    isLow ? 'border-yellow-400 bg-gradient-to-r from-yellow-50 to-orange-50' :
    'border-red-300 bg-gradient-to-r from-red-50 to-orange-50'
  );
</script>

<div class="rounded-xl border-2 p-4 transition-all duration-500 {cardBorder}">
  <!-- Header row -->
  <div class="flex items-center gap-3 mb-2">
    <div class="transition-all duration-300 {emojiClass}" style="display: inline-block;">
      <EnemySprite enemyType="boss" {subject} variant={0}
        state={isDead ? 'defeated' : isEscaped ? 'idle' : phase === 'charging' ? 'attacking' : 'idle'}
        size="md" />
    </div>
    <div class="flex-1">
      <div class="flex items-center gap-2">
        <span class="text-xs font-bold text-red-500 uppercase tracking-wider">Boss Encounter</span>
        {#if isLow}
          <span class="text-[10px] font-bold bg-yellow-200 text-yellow-700 px-1.5 py-0.5 rounded">虚弱</span>
        {/if}
        {#if isDead}
          <span class="text-[10px] font-bold bg-green-200 text-green-700 px-1.5 py-0.5 rounded">已击败</span>
        {/if}
      </div>
      <h3 class="text-base font-bold text-gray-800">{bossName}</h3>
      <p class="text-xs text-gray-500">{bossTitle}</p>
    </div>
    <div class="text-right">
      <span class="text-2xl font-black tabular-nums {isDead ? 'text-green-500' : isLow ? 'text-yellow-500' : 'text-red-500'}">
        {Math.max(0, bossHp)}
      </span>
      <span class="text-xs text-gray-400"> / {bossMaxHp}</span>
    </div>
  </div>

  <!-- HP bar -->
  <div class="w-full h-4 bg-gray-200 rounded-full overflow-hidden relative">
    <!-- Fill bar -->
    <div
      class="h-full rounded-full bg-gradient-to-r {barGradient} {barGlow}"
      style="width: {hpPercent}%; transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);"
    ></div>

    <!-- Shimmer overlay (alive and not escaped) -->
    {#if !isDead && !isEscaped}
      <div class="absolute inset-0 overflow-hidden rounded-full pointer-events-none">
        <div class="absolute inset-y-0 w-1/3 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"
          style="animation: shimmer 1.5s ease-in-out infinite;"></div>
      </div>
    {/if}

    <!-- Low HP pulse border -->
    {#if isLow}
      <div class="absolute inset-0 rounded-full ring-2 ring-yellow-400/50 animate-pulse pointer-events-none"></div>
    {/if}

    <!-- HP break markers -->
    <div class="absolute inset-0 flex pointer-events-none">
      {#each [25, 50, 75] as mark}
        <div class="w-px h-full bg-white/20" style="position: absolute; left: {mark}%;"></div>
      {/each}
    </div>
  </div>

  <!-- Status message -->
  <div class="mt-2 text-center text-xs font-medium">
    {#if isDead}
      <span class="text-green-600 animate-bounce-in inline-block">🏆 {bossName} 被击败！+20 能量奖励</span>
    {:else if isEscaped}
      <span class="text-gray-500">{bossName} 逃走了…</span>
    {:else if phase === 'charging'}
      <span class="text-red-500 animate-pulse">⚠️ {bossName} 正在蓄力…准备迎战！</span>
    {:else if isLow}
      <span class="text-yellow-600">💢 Boss 进入虚弱状态！</span>
    {:else}
      <span class="text-red-400">⚠️ 击败 Boss 可获得额外能量！答错会被反击</span>
    {/if}
  </div>
</div>

<style>
  @keyframes shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(400%); }
  }
</style>
