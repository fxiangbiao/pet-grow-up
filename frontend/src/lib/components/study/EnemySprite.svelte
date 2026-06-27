<script lang="ts">
  /**
   * EnemySprite — SVG-drawn enemy/monster characters for adventure battles.
   *
   * Each subject has 3 minion variants + 1 boss.
   * States: idle | attacking | hit | defeated
   */
  let {
    enemyType = 'minion', // 'minion' | 'boss' | 'elite'
    subject = 'chinese',
    variant = 0,          // 0-2 for minions, 0 for boss
    state = 'idle',       // 'idle' | 'attacking' | 'hit' | 'defeated'
    size = 'md'           // 'sm' | 'md' | 'lg'
  }: {
    enemyType?: string;
    subject?: string;
    variant?: number;
    state?: string;
    size?: string;
  } = $props();

  const subjectColors: Record<string, { primary: string; secondary: string; accent: string }> = {
    chinese: { primary: '#8B4513', secondary: '#D2691E', accent: '#FFD700' },
    math: { primary: '#1E90FF', secondary: '#4169E1', accent: '#00CED1' },
    english: { primary: '#9370DB', secondary: '#8A2BE2', accent: '#FF69B4' }
  };
  const c = $derived(subjectColors[subject] || subjectColors.chinese);

  const sizeDim = $derived(size === 'sm' ? 60 : size === 'lg' ? 140 : 100);
  const cx = $derived(sizeDim / 2);
  const cy = $derived(sizeDim / 2);
  const unit = $derived(sizeDim / 20);

  const isDefeated = $derived(state === 'defeated');
  const isHit = $derived(state === 'hit');
  const isAttacking = $derived(state === 'attacking');

  // Enemy type descriptions
  const enemyData: Record<string, Record<number, { name: string; emoji: string }>> = {
    chinese: {
      0: { name: '墨水妖', emoji: '🔵' },
      1: { name: '笔怪', emoji: '🖊' },
      2: { name: '书虫', emoji: '🐛' },
      3: { name: '黑暗诗魔', emoji: '🐉' }
    },
    math: {
      0: { name: '三角怪', emoji: '🔺' },
      1: { name: '方块精', emoji: '🟫' },
      2: { name: '圆球魔', emoji: '🟣' },
      3: { name: '混沌几何体', emoji: '🔮' }
    },
    english: {
      0: { name: '字母怪', emoji: '🔤' },
      1: { name: '扫帚妖', emoji: '🧹' },
      2: { name: '语法魔', emoji: '📝' },
      3: { name: '暗影巫师', emoji: '🧙' }
    }
  };

  const data = $derived(enemyData[subject]?.[variant] || enemyData.chinese[0]);

  const containerClass = $derived(
    isDefeated ? 'opacity-30 grayscale scale-90' :
    isHit ? 'animate-shake' :
    isAttacking ? 'animate-bounce-in' :
    'animate-breathe'
  );
</script>

<div class="relative inline-flex items-center justify-center {containerClass}"
  style="width: {sizeDim}px; height: {sizeDim}px; transition: all 0.4s ease;"
  role="img" aria-label={data.name}>
  <svg width={sizeDim} height={sizeDim} viewBox="0 0 {sizeDim} {sizeDim}" class="overflow-visible">
    <defs>
      <filter id="es-glow-{variant}">
        <feGaussianBlur stdDeviation="2" result="blur" />
        <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
      </filter>
    </defs>

    {#if enemyType === 'boss'}
      <!-- === BOSS: Large menacing creature === -->
      <!-- Boss body -->
      <ellipse cx={cx} cy={cy + unit * 2} rx={unit * 8} ry={unit * 6}
        fill="{c.primary}20" stroke={c.primary} stroke-width="2.5" filter="url(#es-glow-{variant})" />
      <!-- Boss head -->
      <circle cx={cx} cy={cy - unit * 2} r={unit * 5.5}
        fill="{c.primary}15" stroke={c.primary} stroke-width="2.5" />
      <!-- Menacing eyes -->
      <ellipse cx={cx - unit * 2.5} cy={cy - unit * 3} rx={unit * 1.5} ry={unit * 1.8}
        fill={c.primary} opacity="0.8" />
      <ellipse cx={cx + unit * 2.5} cy={cy - unit * 3} rx={unit * 1.5} ry={unit * 1.8}
        fill={c.primary} opacity="0.8" />
      <circle cx={cx - unit * 2.5} cy={cy - unit * 2.8} r={unit * 0.5} fill="white" opacity="0.6" />
      <circle cx={cx + unit * 2.5} cy={cy - unit * 2.8} r={unit * 0.5} fill="white" opacity="0.6" />
      <!-- Angry mouth -->
      <path d="M{cx - unit * 2.5},{cy} Q{cx},{cy + unit * 3} {cx + unit * 2.5},{cy}"
        fill="none" stroke={c.primary} stroke-width="2" stroke-linecap="round" opacity="0.7" />
      <!-- Boss horns/spikes -->
      <polygon points="{cx - unit * 4},{cy - unit * 5} {cx - unit * 3},{cy - unit * 8} {cx - unit * 2},{cy - unit * 5}"
        fill={c.secondary} opacity="0.5" />
      <polygon points="{cx + unit * 2},{cy - unit * 5} {cx + unit * 3},{cy - unit * 8} {cx + unit * 4},{cy - unit * 5}"
        fill={c.secondary} opacity="0.5" />
      <!-- Boss aura -->
      <circle cx={cx} cy={cy} r={unit * 10}
        fill="none" stroke={c.accent} stroke-width="1.5" opacity="0.25" stroke-dasharray="6 4" />
      {#if !isDefeated}
        <circle cx={cx} cy={cy} r={unit * 10}
          fill="none" stroke={c.accent} stroke-width="1" opacity="0.15" class="animate-spin"
          style="transform-origin: {cx}px {cy}px; animation-duration: 12s;" />
      {/if}

    {:else}
      <!-- === MINION / ELITE === -->
      <!-- Body blob -->
      <ellipse cx={cx} cy={cy + unit * 1.5} rx={unit * 5} ry={unit * 4}
        fill="{c.primary}15" stroke={c.primary} stroke-width="1.8" />
      <!-- Head -->
      <circle cx={cx} cy={cy - unit * 1.5} r={unit * 3.5}
        fill="{c.primary}12" stroke={c.primary} stroke-width="1.8" />
      <!-- Eyes (simple dots) -->
      <circle cx={cx - unit * 1.5} cy={cy - unit * 2} r={unit * 0.8} fill={c.primary} opacity="0.7" />
      <circle cx={cx + unit * 1.5} cy={cy - unit * 2} r={unit * 0.8} fill={c.primary} opacity="0.7" />
      <!-- Mouth (grumpy) -->
      <path d="M{cx - unit},{cy - unit * 0.3} Q{cx},{cy + unit * 1.5} {cx + unit},{cy - unit * 0.3}"
        fill="none" stroke={c.primary} stroke-width="1.3" stroke-linecap="round" opacity="0.5" />
      <!-- Subject-specific features -->
      {#if subject === 'chinese'}
        <!-- Ink splotch -->
        <circle cx={cx} cy={cy + unit * 3.5} r={unit * 2.5} fill={c.primary} opacity="0.12" />
        {#if variant === 0}
          <circle cx={cx - unit * 3.5} cy={cy + unit * 1} r={unit * 1.2} fill={c.primary} opacity="0.15" />
        {:else if variant === 1}
          <line x1={cx + unit * 3} y1={cy} x2={cx + unit * 6} y2={cy - unit * 2}
            stroke={c.secondary} stroke-width="1.5" stroke-linecap="round" opacity="0.5" />
        {:else}
          <path d="M{cx - unit * 4},{cy - unit * 4} Q{cx},{cy - unit * 7} {cx + unit * 4},{cy - unit * 4}"
            fill="none" stroke={c.secondary} stroke-width="1.2" opacity="0.4" />
        {/if}
      {:else if subject === 'math'}
        <!-- Geometric decorations -->
        {#if variant === 0}
          <polygon points="{cx},{cy - unit * 5.5} {cx + unit * 4},{cy + unit * 1.5} {cx - unit * 4},{cy + unit * 1.5}"
            fill="none" stroke={c.accent} stroke-width="1" opacity="0.4" />
        {:else if variant === 1}
          <rect x={cx - unit * 3} y={cy - unit * 3} width={unit * 6} height={unit * 6}
            fill="none" stroke={c.accent} stroke-width="1" opacity="0.4" rx="1" />
        {:else}
          <circle cx={cx} cy={cy + unit * 2} r={unit * 3}
            fill="none" stroke={c.accent} stroke-width="1" opacity="0.4" />
        {/if}
      {:else}
        <!-- Magical marks -->
        {#if variant === 0}
          <text x={cx} y={cy + unit * 5} text-anchor="middle" font-size={unit * 4}
            fill={c.primary} opacity="0.15">?</text>
        {:else if variant === 1}
          <line x1={cx - unit * 4} y1={cy + unit * 2} x2={cx + unit * 4} y2={cy + unit * 2}
            stroke={c.secondary} stroke-width="1.5" opacity="0.4" />
        {:else}
          <circle cx={cx} cy={cy + unit * 3} r={unit * 1.5} fill="none"
            stroke={c.accent} stroke-width="1" opacity="0.5" stroke-dasharray="3 2" />
        {/if}
      {/if}
    {/if}

    <!-- Defeated marker -->
    {#if isDefeated}
      <line x1={cx - unit * 7} y1={cy - unit * 7} x2={cx + unit * 7} y2={cy + unit * 7}
        stroke="#ef4444" stroke-width="2" opacity="0.6" />
      <line x1={cx + unit * 7} y1={cy - unit * 7} x2={cx - unit * 7} y2={cy + unit * 7}
        stroke="#ef4444" stroke-width="2" opacity="0.6" />
    {/if}

    <!-- Hit flash -->
    {#if isHit}
      <circle cx={cx} cy={cy} r={unit * 9} fill="white" opacity="0.3" class="animate-sparkle" />
    {/if}
  </svg>

  <!-- Enemy name label -->
  {#if size !== 'sm' && enemyType !== 'minion'}
    <div class="absolute -bottom-1 left-1/2 -translate-x-1/2 text-[10px] font-bold text-gray-500 whitespace-nowrap">
      {data.name}
    </div>
  {/if}
</div>
