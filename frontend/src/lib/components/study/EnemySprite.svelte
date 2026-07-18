<script lang="ts">
  /**
   * EnemySprite — Cute cartoon SVG enemies for adventure battles.
   * Each subject has 3 minion variants + 1 boss.
   * States: idle | hit | defeated | attacking
   */
  let {
    enemyType = 'minion',
    subject = 'chinese',
    variant = 0,
    state = 'idle',
    size = 'md'
  }: {
    enemyType?: string;
    subject?: string;
    variant?: number;
    state?: string;
    size?: string;
  } = $props();

  const sizeDim = $derived(size === 'sm' ? 60 : size === 'lg' ? 140 : 100);
  const cx = $derived(sizeDim / 2);
  const cy = $derived(sizeDim / 2);
  const u = $derived(sizeDim / 20); // unit

  const isDefeated = $derived(state === 'defeated');
  const isHit = $derived(state === 'hit');
  const isAttacking = $derived(state === 'attacking');

  // Cute enemy data with emoji fallbacks
  const enemies: Record<string, Record<number, { name: string; emoji: string; color: string; bodyColor: string }>> = {
    chinese: {
      0: { name: '书虫', emoji: '🐛', color: '#8B6914', bodyColor: '#C4A44A' },
      1: { name: '错别字怪', emoji: '👻', color: '#6B48A8', bodyColor: '#9B78D0' },
      2: { name: '墨水妖', emoji: '🫧', color: '#2563EB', bodyColor: '#60A5FA' },
      3: { name: '诗词巨龙', emoji: '🐉', color: '#DC2626', bodyColor: '#F87171' }
    },
    math: {
      0: { name: '数字怪', emoji: '🔢', color: '#1D4ED8', bodyColor: '#60A5FA' },
      1: { name: '除号怪', emoji: '➗', color: '#059669', bodyColor: '#34D399' },
      2: { name: '几何怪', emoji: '🔷', color: '#7C3AED', bodyColor: '#A78BFA' },
      3: { name: '算术魔王', emoji: '👹', color: '#B91C1C', bodyColor: '#F87171' }
    },
    english: {
      0: { name: '字母怪', emoji: '🔤', color: '#7C3AED', bodyColor: '#A78BFA' },
      1: { name: '语法怪', emoji: '📝', color: '#0891B2', bodyColor: '#22D3EE' },
      2: { name: '发音魔', emoji: '🎵', color: '#DB2777', bodyColor: '#F472B6' },
      3: { name: '单词巫师', emoji: '🧙', color: '#4338CA', bodyColor: '#818CF8' }
    }
  };

  const data = $derived(enemies[subject]?.[variant] || enemies.chinese[0]);
  const isBoss = $derived(enemyType === 'boss');

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
      <filter id="cute-glow-{subject}-{variant}">
        <feGaussianBlur stdDeviation="1.5" result="blur" />
        <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
      </filter>
    </defs>

    {#if isBoss}
      <!-- === BOSS: Big cute but menacing === -->
      <!-- Body -->
      <ellipse cx={cx} cy={cy + u*2} rx={u*7} ry={u*5.5}
        fill={data.bodyColor} opacity="0.3" />
      <ellipse cx={cx} cy={cy + u*2} rx={u*7} ry={u*5.5}
        fill="none" stroke={data.color} stroke-width="2.5" />
      <!-- Head -->
      <circle cx={cx} cy={cy - u*2} r={u*5}
        fill={data.bodyColor} opacity="0.25" />
      <circle cx={cx} cy={cy - u*2} r={u*5}
        fill="none" stroke={data.color} stroke-width="2.5" />
      <!-- Big cute eyes -->
      <ellipse cx={cx - u*2} cy={cy - u*2.5} rx={u*1.8} ry={u*2}
        fill="white" stroke={data.color} stroke-width="1.5" />
      <ellipse cx={cx + u*2} cy={cy - u*2.5} rx={u*1.8} ry={u*2}
        fill="white" stroke={data.color} stroke-width="1.5" />
      <circle cx={cx - u*1.8} cy={cy - u*2.2} r={u*0.9} fill={data.color} />
      <circle cx={cx + u*1.8} cy={cy - u*2.2} r={u*0.9} fill={data.color} />
      <circle cx={cx - u*1.5} cy={cy - u*2.5} r={u*0.35} fill="white" />
      <circle cx={cx + u*2.1} cy={cy - u*2.5} r={u*0.35} fill="white" />
      <!-- Angry cute mouth -->
      <path d="M{cx - u*2},{cy + u*0.5} Q{cx},{cy + u*2.5} {cx + u*2},{cy + u*0.5}"
        fill="none" stroke={data.color} stroke-width="2" stroke-linecap="round" />
      <!-- Boss horns -->
      <circle cx={cx - u*3.5} cy={cy - u*5.5} r={u*1.2} fill={data.bodyColor} opacity="0.5" />
      <circle cx={cx + u*3.5} cy={cy - u*5.5} r={u*1.2} fill={data.bodyColor} opacity="0.5" />
      <!-- Boss aura -->
      <circle cx={cx} cy={cy} r={u*9}
        fill="none" stroke={data.color} stroke-width="1" opacity="0.2" stroke-dasharray="4 3" />
      <!-- Boss emoji label -->
      <text x={cx} y={cy + u*8} text-anchor="middle" font-size={u*3}>{data.emoji}</text>

    {:else}
      <!-- === MINION: Cute blob creature === -->
      <!-- Body -->
      <ellipse cx={cx} cy={cy + u*1.5} rx={u*4.5} ry={u*3.5}
        fill={data.bodyColor} opacity="0.25" />
      <ellipse cx={cx} cy={cy + u*1.5} rx={u*4.5} ry={u*3.5}
        fill="none" stroke={data.color} stroke-width="1.8" />
      <!-- Head -->
      <circle cx={cx} cy={cy - u*1.5} r={u*3.2}
        fill={data.bodyColor} opacity="0.2" />
      <circle cx={cx} cy={cy - u*1.5} r={u*3.2}
        fill="none" stroke={data.color} stroke-width="1.8" />
      <!-- Cute eyes -->
      <circle cx={cx - u*1.3} cy={cy - u*1.8} r={u*1} fill="white" stroke={data.color} stroke-width="1" />
      <circle cx={cx + u*1.3} cy={cy - u*1.8} r={u*1} fill="white" stroke={data.color} stroke-width="1" />
      <circle cx={cx - u*1.1} cy={cy - u*1.6} r={u*0.5} fill={data.color} />
      <circle cx={cx + u*1.5} cy={cy - u*1.6} r={u*0.5} fill={data.color} />
      <circle cx={cx - u*0.9} cy={cy - u*1.9} r={u*0.2} fill="white" />
      <circle cx={cx + u*1.7} cy={cy - u*1.9} r={u*0.2} fill="white" />
      <!-- Cute mouth -->
      <path d="M{cx - u*0.8},{cy - u*0.2} Q{cx},{cy + u*0.8} {cx + u*0.8},{cy - u*0.2}"
        fill="none" stroke={data.color} stroke-width="1.2" stroke-linecap="round" />
      <!-- Blush -->
      <ellipse cx={cx - u*2.5} cy={cy - u*0.8} rx={u*0.8} ry={u*0.5} fill="#FFB6C1" opacity="0.4" />
      <ellipse cx={cx + u*2.5} cy={cy - u*0.8} rx={u*0.8} ry={u*0.5} fill="#FFB6C1" opacity="0.4" />
      <!-- Subject-specific cute accessory -->
      {#if subject === 'chinese'}
        <text x={cx} y={cy - u*5} text-anchor="middle" font-size={u*2.5} opacity="0.6">
          {variant === 0 ? '📖' : variant === 1 ? '✏️' : '📜'}
        </text>
      {:else if subject === 'math'}
        <text x={cx} y={cy - u*5} text-anchor="middle" font-size={u*2.5} opacity="0.6">
          {variant === 0 ? '🔢' : variant === 1 ? '➗' : '📐'}
        </text>
      {:else}
        <text x={cx} y={cy - u*5} text-anchor="middle" font-size={u*2.5} opacity="0.6">
          {variant === 0 ? '🔤' : variant === 1 ? '📝' : '🎵'}
        </text>
      {/if}
      <!-- Little feet -->
      <ellipse cx={cx - u*2} cy={cy + u*4.5} rx={u*1.5} ry={u*0.8} fill={data.bodyColor} opacity="0.3" />
      <ellipse cx={cx + u*2} cy={cy + u*4.5} rx={u*1.5} ry={u*0.8} fill={data.bodyColor} opacity="0.3" />
    {/if}

    <!-- Defeated X marks -->
    {#if isDefeated}
      <line x1={cx - u*1.5} y1={cy - u*2.5} x2={cx - u*0.5} y2={cy - u*1.5}
        stroke="#ef4444" stroke-width="2" opacity="0.7" />
      <line x1={cx - u*0.5} y1={cy - u*2.5} x2={cx - u*1.5} y2={cy - u*1.5}
        stroke="#ef4444" stroke-width="2" opacity="0.7" />
      <line x1={cx + u*0.5} y1={cy - u*2.5} x2={cx + u*1.5} y2={cy - u*1.5}
        stroke="#ef4444" stroke-width="2" opacity="0.7" />
      <line x1={cx + u*1.5} y1={cy - u*2.5} x2={cx + u*0.5} y2={cy - u*1.5}
        stroke="#ef4444" stroke-width="2" opacity="0.7" />
    {/if}

    <!-- Hit flash -->
    {#if isHit}
      <circle cx={cx} cy={cy} r={u*8} fill="white" opacity="0.3">
        <animate attributeName="opacity" from="0.4" to="0" dur="0.4s" fill="freeze" />
      </circle>
      <!-- Stars -->
      <text x={cx - u*4} y={cy - u*4} font-size={u*2} opacity="0.8">⭐</text>
      <text x={cx + u*3} y={cy - u*5} font-size={u*1.5} opacity="0.6">💫</text>
    {/if}
  </svg>

  <!-- Name label for boss -->
  {#if size !== 'sm' && isBoss}
    <div class="absolute -bottom-1 left-1/2 -translate-x-1/2 text-[10px] font-bold text-gray-500 whitespace-nowrap bg-white/70 px-1.5 rounded">
      {data.name}
    </div>
  {/if}
</div>
