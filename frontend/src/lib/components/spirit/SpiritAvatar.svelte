<script lang="ts">
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    species,
    evolutionStage = 1,
    size = 'md',
    animated = true,
    mood = 'idle',
    onclick
  }: {
    species: SpiritSpecies;
    evolutionStage?: number;
    size?: 'sm' | 'md' | 'lg';
    animated?: boolean;
    mood?: 'idle' | 'happy' | 'excited' | 'hurt';
    onclick?: () => void;
  } = $props();

  // Image loading
  let imgLoaded = $state(false);
  let imgError = $state(false);
  let clicked = $state(false);

  const spriteUrl = $derived(species?.spriteUrl || '');
  const useImage = $derived(!!spriteUrl && imgLoaded && !imgError);

  // Click feedback
  function handleClick() {
    clicked = true;
    setTimeout(() => { clicked = false; }, 400);
    if (onclick) onclick();
  }

  // SVG fallback geometry
  const subjectConfig: Record<string, { colors: Record<string, string> }> = {
    chinese: { colors: { primary: '#8B4513', secondary: '#D2691E', accent: '#FFD700', glow: 'rgba(255, 215, 0, 0.6)' } },
    math: { colors: { primary: '#1E90FF', secondary: '#4169E1', accent: '#00CED1', glow: 'rgba(0, 206, 209, 0.6)' } },
    english: { colors: { primary: '#9370DB', secondary: '#8A2BE2', accent: '#FF69B4', glow: 'rgba(255, 105, 180, 0.6)' } }
  };

  const sizeMap = {
    sm: { svg: 80, icon: 36, orbit: 32 },
    md: { svg: 140, icon: 56, orbit: 50 },
    lg: { svg: 200, icon: 80, orbit: 72 }
  };

  const config = $derived(subjectConfig[species.subject as keyof typeof subjectConfig] || subjectConfig.chinese);
  const dim = $derived(sizeMap[size]);
  const stage = $derived(Math.min(Math.max(evolutionStage, 1), 3));
  const cx = $derived(dim.svg / 2);
  const cy = $derived(dim.svg / 2);
  const r = $derived(dim.svg * 0.42);
  const orbitR = $derived(dim.orbit);
  const primaryHex = $derived(config.colors.primary);
  const secondaryHex = $derived(config.colors.secondary);
  const accentHex = $derived(config.colors.accent);
  const half = $derived(dim.icon / 2);

  const iconPath = $derived.by(() => {
    switch (species.subject) {
      case 'chinese': return [
        `M${cx - half * 0.6},${cy - half * 0.8}`, `L${cx + half * 0.6},${cy - half * 0.8}`,
        `L${cx + half * 0.7},${cy - half * 0.3}`, `L${cx + half * 0.6},${cy}`,
        `L${cx + half * 0.7},${cy + half * 0.3}`, `L${cx + half * 0.6},${cy + half * 0.8}`,
        `L${cx - half * 0.6},${cy + half * 0.8}`, `L${cx - half * 0.7},${cy + half * 0.3}`,
        `L${cx - half * 0.6},${cy}`, `L${cx - half * 0.7},${cy - half * 0.3}`, 'Z'
      ].join(' ');
      case 'math': {
        const pts: string[] = [];
        for (let i = 0; i < 6; i++) pts.push(`${cx + half * 0.75 * Math.cos((Math.PI / 3) * i - Math.PI / 2)},${cy + half * 0.75 * Math.sin((Math.PI / 3) * i - Math.PI / 2)}`);
        return pts.join(' ');
      }
      case 'english': return [
        `M${cx},${cy - half * 0.9}`, `L${cx + half * 0.25},${cy - half * 0.25}`,
        `L${cx + half * 0.9},${cy}`, `L${cx + half * 0.25},${cy + half * 0.25}`,
        `L${cx},${cy + half * 0.9}`, `L${cx - half * 0.25},${cy + half * 0.25}`,
        `L${cx - half * 0.9},${cy}`, `L${cx - half * 0.25},${cy - half * 0.25}`, 'Z'
      ].join(' ');
      default: return '';
    }
  });

  const innerTrianglePath = $derived.by(() => {
    if (species.subject !== 'math') return '';
    const pts: string[] = [];
    for (let i = 0; i < 3; i++) pts.push(`${cx + half * 0.4 * Math.cos((Math.PI * 2 / 3) * i - Math.PI / 2)},${cy + half * 0.4 * Math.sin((Math.PI * 2 / 3) * i - Math.PI / 2)}`);
    return pts.join(' ');
  });

  const particles = $derived.by(() => {
    const result: Array<{ angle: number; size: number; color: string; delay: number; speed: number }> = [];
    const count = stage >= 3 ? 4 : stage >= 2 ? 2 : 0;
    for (let i = 0; i < count; i++) result.push({
      angle: (360 / count) * i, size: stage >= 3 ? 5 : 4,
      color: i % 2 === 0 ? primaryHex : accentHex, delay: i * 0.5, speed: 3 + i * 0.5
    });
    return result;
  });

  const sparkles = $derived.by(() => {
    if (stage < 3) return [];
    const result: Array<{ x: number; y: number; size: number; delay: number }> = [];
    const spread = dim.svg * 0.35;
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 3) * i;
      result.push({ x: cx + spread * Math.cos(angle), y: cy + spread * Math.sin(angle), size: 3 + ((i * 7) % 4), delay: i * 0.3 });
    }
    return result;
  });

  const animClass = $derived(
    mood === 'excited' ? 'animate-bounce-in' :
    mood === 'hurt' ? 'animate-shake' :
    clicked ? 'animate-bounce-in' :
    animated ? 'animate-float' : ''
  );

  const stageColor = $derived(
    stage === 1 ? 'from-indigo-400 to-purple-500' :
    stage === 2 ? 'from-amber-400 to-orange-500' :
    'from-red-400 to-pink-500'
  );
</script>

<div
  class="relative inline-flex items-center justify-center {animClass}"
  class:cursor-pointer={!!onclick}
  style="width: {dim.svg}px; height: {dim.svg}px;"
  onclick={handleClick}
  role={onclick ? 'button' : undefined}
  onkeydown={(e) => { if (onclick && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); handleClick(); } }}
>
  {#if useImage}
    <!-- Real sprite image -->
    <img
      src={spriteUrl}
      alt={species?.name || 'Spirit'}
      class="w-full h-full object-contain drop-shadow-lg
        {animated ? 'animate-breathe' : ''}"
      draggable={false}
    />
  {:else}
    <!-- Fallback SVG abstract art -->
    <svg
      width={dim.svg}
      height={dim.svg}
      viewBox="0 0 {dim.svg} {dim.svg}"
      class="overflow-visible"
    >
      <defs>
        <filter id="glow-{species.id}" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="{stage * 2}" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <filter id="pg-{species.id}">
          <feGaussianBlur stdDeviation="1.5" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
      </defs>

      <circle cx={cx} cy={cy} r={r}
        fill="{secondaryHex}15" stroke={primaryHex} stroke-width="2"
        class:animate-pulse-glow={animated && stage >= 2}
        style="filter: url(#glow-{species.id});" />
      <circle cx={cx} cy={cy} r={r * 0.75} fill="{primaryHex}10" />

      {#if species.subject === 'chinese'}
        <!-- Chibi Scholar — 小书童/诗灵/文圣 -->
        <!-- Body (robe) -->
        <ellipse cx={cx} cy={cy + half * 0.35} rx={half * 0.35} ry={half * 0.28}
          fill="{primaryHex}25" stroke={primaryHex} stroke-width="1.5" />
        <!-- Head -->
        <circle cx={cx} cy={cy - half * 0.12} r={half * 0.25}
          fill="#FFF8E7" stroke={primaryHex} stroke-width="1.8" />
        <!-- Scholar hat -->
        <rect x={cx - half * 0.22} y={cy - half * 0.45} width={half * 0.44} height={half * 0.1}
          fill={primaryHex} opacity="0.7" rx="2" />
        <rect x={cx - half * 0.14} y={cy - half * 0.55} width={half * 0.28} height={half * 0.12}
          fill={primaryHex} opacity="0.8" rx="1" />
        {#if stage >= 2}
          <circle cx={cx} cy={cy - half * 0.58} r="2.5" fill={accentHex} />
        {/if}
        <!-- Scroll/book in hand -->
        <rect x={cx - half * 0.3} y={cy + half * 0.18} width={half * 0.25} height={half * 0.15}
          fill="#FFF8E7" stroke={secondaryHex} stroke-width="1" rx="1" transform="rotate(-15,{cx - half * 0.17},{cy + half * 0.25})" />
        <!-- Arms -->
        <line x1={cx - half * 0.3} y1={cy + half * 0.08} x2={cx - half * 0.15} y2={cy + half * 0.22}
          stroke={primaryHex} stroke-width="2" stroke-linecap="round" opacity="0.6" />
        <line x1={cx + half * 0.3} y1={cy + half * 0.08} x2={cx + half * 0.2} y2={cy + half * 0.05}
          stroke={primaryHex} stroke-width="2" stroke-linecap="round" opacity="0.6" />

      {:else if species.subject === 'math'}
        <!-- Chibi Cat — 智慧猫/数学龙/逻辑神 -->
        <!-- Body -->
        <ellipse cx={cx} cy={cy + half * 0.3} rx={half * 0.3} ry={half * 0.25}
          fill="{primaryHex}20" stroke={primaryHex} stroke-width="1.5" />
        <!-- Head -->
        <circle cx={cx} cy={cy - half * 0.1} r={half * 0.24}
          fill="#F0F8FF" stroke={primaryHex} stroke-width="1.8" />
        <!-- Cat ears -->
        <polygon points="{cx - half * 0.2},{cy - half * 0.28} {cx - half * 0.14},{cy - half * 0.5} {cx - half * 0.04},{cy - half * 0.28}"
          fill="{primaryHex}20" stroke={primaryHex} stroke-width="1.3" />
        <polygon points="{cx + half * 0.04},{cy - half * 0.28} {cx + half * 0.14},{cy - half * 0.5} {cx + half * 0.2},{cy - half * 0.28}"
          fill="{primaryHex}20" stroke={primaryHex} stroke-width="1.3" />
        <!-- Inner ear -->
        <polygon points="{cx - half * 0.17},{cy - half * 0.3} {cx - half * 0.13},{cy - half * 0.46} {cx - half * 0.07},{cy - half * 0.3}"
          fill={accentHex} opacity="0.3" />
        <polygon points="{cx + half * 0.07},{cy - half * 0.3} {cx + half * 0.13},{cy - half * 0.46} {cx + half * 0.17},{cy - half * 0.3}"
          fill={accentHex} opacity="0.3" />
        <!-- Glasses -->
        <circle cx={cx - half * 0.1} cy={cy - half * 0.12} r={half * 0.09}
          fill="none" stroke={accentHex} stroke-width="1.2" opacity="0.8" />
        <circle cx={cx + half * 0.1} cy={cy - half * 0.12} r={half * 0.09}
          fill="none" stroke={accentHex} stroke-width="1.2" opacity="0.8" />
        <line x1={cx - half * 0.01} y1={cy - half * 0.12} x2={cx + half * 0.01} y2={cy - half * 0.12}
          stroke={accentHex} stroke-width="1" opacity="0.8" />
        {#if stage >= 2}
          <!-- Small wings -->
          <path d="M{cx - half * 0.28},{cy + half * 0.05} Q{cx - half * 0.55},{cy - half * 0.1} {cx - half * 0.25},{cy - half * 0.15} Z"
            fill="{secondaryHex}30" stroke={accentHex} stroke-width="1" opacity="0.6" />
          <path d="M{cx + half * 0.28},{cy + half * 0.05} Q{cx + half * 0.55},{cy - half * 0.1} {cx + half * 0.25},{cy - half * 0.15} Z"
            fill="{secondaryHex}30" stroke={accentHex} stroke-width="1" opacity="0.6" />
        {/if}

      {:else if species.subject === 'english'}
        <!-- Chibi Wizard — 小巫师/魔法鸦/大魔导师 -->
        <!-- Body (robe) -->
        <ellipse cx={cx} cy={cy + half * 0.32} rx={half * 0.32} ry={half * 0.26}
          fill="{primaryHex}20" stroke={primaryHex} stroke-width="1.5" />
        <!-- Head -->
        <circle cx={cx} cy={cy - half * 0.1} r={half * 0.24}
          fill="#F8F0FF" stroke={primaryHex} stroke-width="1.8" />
        <!-- Wizard hat -->
        <polygon points="{cx - half * 0.2},{cy - half * 0.3} {cx},{cy - half * 0.65} {cx + half * 0.2},{cy - half * 0.3}"
          fill={primaryHex} opacity="0.7" stroke={primaryHex} stroke-width="1.2" />
        <ellipse cx={cx} cy={cy - half * 0.3} rx={half * 0.22} ry={half * 0.04}
          fill={primaryHex} opacity="0.5" />
        {#if stage >= 2}
          <circle cx={cx} cy={cy - half * 0.67} r="3" fill={accentHex} opacity="0.9" />
        {/if}
        <!-- Wand -->
        <line x1={cx + half * 0.22} y1={cy + half * 0.05} x2={cx + half * 0.42} y2={cy - half * 0.15}
          stroke={secondaryHex} stroke-width="2" stroke-linecap="round" />
        <circle cx={cx + half * 0.42} cy={cy - half * 0.18} r="3" fill={accentHex} opacity="0.8" />
        <!-- Arms -->
        <line x1={cx - half * 0.28} y1={cy + half * 0.05} x2={cx - half * 0.15} y2={cy + half * 0.2}
          stroke={primaryHex} stroke-width="1.8" stroke-linecap="round" opacity="0.6" />

      {:else}
        <circle cx={cx} cy={cy} r={half * 0.4} fill="{primaryHex}20" stroke={primaryHex} stroke-width="2.5" />
      {/if}

      <!-- ── Facial features ── -->
      {#if species.subject}
        {@const eyeY = cy - half * 0.08}
        {@const eyeSpacing = half * 0.3}
        {@const eyeR = half * 0.08}
        {@const mouthY = cy + half * 0.2}

        <!-- Blush (happy/excited only) -->
        {#if mood === 'happy' || mood === 'excited'}
          <circle cx={cx - eyeSpacing - 2} cy={eyeY + half * 0.12} r={half * 0.1}
            fill={accentHex} opacity="0.3" />
          <circle cx={cx + eyeSpacing + 2} cy={eyeY + half * 0.12} r={half * 0.1}
            fill={accentHex} opacity="0.3" />
        {/if}

        <!-- Eyes -->
        {#if mood === 'hurt'}
          <!-- X_X hurt eyes -->
          <g stroke={primaryHex} stroke-width="2" stroke-linecap="round" opacity="0.9">
            <line x1={cx - eyeSpacing - eyeR} y1={eyeY - eyeR} x2={cx - eyeSpacing + eyeR} y2={eyeY + eyeR} />
            <line x1={cx - eyeSpacing + eyeR} y1={eyeY - eyeR} x2={cx - eyeSpacing - eyeR} y2={eyeY + eyeR} />
            <line x1={cx + eyeSpacing - eyeR} y1={eyeY - eyeR} x2={cx + eyeSpacing + eyeR} y2={eyeY + eyeR} />
            <line x1={cx + eyeSpacing + eyeR} y1={eyeY - eyeR} x2={cx + eyeSpacing - eyeR} y2={eyeY + eyeR} />
          </g>
        {:else if mood === 'excited'}
          <!-- Star eyes ✨ -->
          <text x={cx - eyeSpacing} y={eyeY + eyeR} text-anchor="middle" font-size={half * 0.2}>⭐</text>
          <text x={cx + eyeSpacing} y={eyeY + eyeR} text-anchor="middle" font-size={half * 0.2}>⭐</text>
        {:else if mood === 'happy'}
          <!-- ^_^ happy curved eyes -->
          <path d="M{cx - eyeSpacing - eyeR},{eyeY + 2} Q{cx - eyeSpacing},{eyeY - eyeR * 1.2} {cx - eyeSpacing + eyeR},{eyeY + 2}"
            fill="none" stroke={primaryHex} stroke-width="2" stroke-linecap="round" opacity="0.9" />
          <path d="M{cx + eyeSpacing - eyeR},{eyeY + 2} Q{cx + eyeSpacing},{eyeY - eyeR * 1.2} {cx + eyeSpacing + eyeR},{eyeY + 2}"
            fill="none" stroke={primaryHex} stroke-width="2" stroke-linecap="round" opacity="0.9" />
        {:else}
          <!-- Normal idle eyes (circles with subtle blink) -->
          <ellipse cx={cx - eyeSpacing} cy={eyeY} rx={eyeR} ry={eyeR * 0.9}
            fill={primaryHex} opacity="0.7" />
          <ellipse cx={cx + eyeSpacing} cy={eyeY} rx={eyeR} ry={eyeR * 0.9}
            fill={primaryHex} opacity="0.7" />
          <!-- Eye shine -->
          <circle cx={cx - eyeSpacing + eyeR * 0.3} cy={eyeY - eyeR * 0.3} r={eyeR * 0.35}
            fill="white" opacity="0.8" />
          <circle cx={cx + eyeSpacing + eyeR * 0.3} cy={eyeY - eyeR * 0.3} r={eyeR * 0.35}
            fill="white" opacity="0.8" />
        {/if}

        <!-- Mouth -->
        {#if mood === 'happy'}
          <path d="M{cx - eyeSpacing * 0.6},{mouthY} Q{cx},{mouthY + half * 0.15} {cx + eyeSpacing * 0.6},{mouthY}"
            fill="none" stroke={primaryHex} stroke-width="1.8" stroke-linecap="round" opacity="0.8" />
        {:else if mood === 'excited'}
          <ellipse cx={cx} cy={mouthY + 2} rx={eyeSpacing * 0.5} ry={half * 0.1}
            fill={primaryHex} opacity="0.6" />
        {:else if mood === 'hurt'}
          <path d="M{cx - eyeSpacing * 0.6},{mouthY + half * 0.12} Q{cx},{mouthY - 2} {cx + eyeSpacing * 0.6},{mouthY + half * 0.12}"
            fill="none" stroke={primaryHex} stroke-width="1.8" stroke-linecap="round" opacity="0.7" />
        {:else}
          <!-- Idle: small neutral line -->
          <line x1={cx - eyeSpacing * 0.5} y1={mouthY + 3} x2={cx + eyeSpacing * 0.5} y2={mouthY + 3}
            stroke={primaryHex} stroke-width="1.5" stroke-linecap="round" opacity="0.5" />
        {/if}
      {/if}

      <!-- ── Evolution stage aura ── -->
      {#if stage >= 3}
        <circle cx={cx} cy={cy} r={r * 1.12}
          fill="none" stroke={accentHex} stroke-width="1.5" opacity="0.35"
          stroke-dasharray="5 3" />
        <circle cx={cx} cy={cy} r={r * 1.22}
          fill="none" stroke={accentHex} stroke-width="0.8" opacity="0.15" />
      {/if}

      {#each particles as p, i}
        <g class={animated ? 'animate-spin' : ''}
          style="transform-origin: {cx}px {cy}px; animation-duration: {p.speed}s; animation-delay: {p.delay}s;">
          <circle cx={cx + orbitR * Math.cos((p.angle * Math.PI) / 180)}
            cy={cy + orbitR * Math.sin((p.angle * Math.PI) / 180)}
            r={p.size} fill={p.color} opacity="0.8" filter="url(#pg-{species.id})"
            style="animation: pp 2s ease-in-out {p.delay}s infinite alternate" />
        </g>
      {/each}

      {#if animated}
        {#each sparkles as sp, i}
          <circle cx={sp.x} cy={sp.y} r={sp.size} fill={accentHex} opacity="0"
            style="animation: sf 1.5s ease-in-out {sp.delay}s infinite" />
        {/each}
      {/if}
    </svg>
  {/if}

  <!-- Stage badge -->
  {#if stage > 1}
    <div class="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-gradient-to-br {stageColor} flex items-center justify-center text-white text-[10px] font-bold shadow-sm">
      {stage}
    </div>
  {/if}

  <!-- Mood expressed via SVG facial features now — no emoji overlay needed -->
</div>

<!-- Hidden image preloader to detect if sprite URL loads -->
{#if spriteUrl && !imgLoaded && !imgError}
  <img
    src={spriteUrl}
    alt="preload"
    class="hidden"
    onload={() => { imgLoaded = true; }}
    onerror={() => { imgError = true; }}
  />
{/if}

<style>
  @keyframes pp { 0% { opacity: 0.4; } 100% { opacity: 1; } }
  @keyframes sf { 0%, 100% { opacity: 0; transform: scale(0.5); } 50% { opacity: 0.9; transform: scale(1.2); } }
  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    20% { transform: translateX(-4px); }
    40% { transform: translateX(4px); }
    60% { transform: translateX(-2px); }
    80% { transform: translateX(2px); }
  }
  :global(.animate-shake) {
    animation: shake 0.4s ease-out;
  }
</style>
