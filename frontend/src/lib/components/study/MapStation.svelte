<script lang="ts">
  import type { StationType } from '$lib/types/adventure-map';
  import { getStationTheme } from '$lib/types/adventure-map';

  let {
    stationType = 'study' as StationType,
    x = 0,
    y = 0,
    index = 0,
    isCurrent = false,
    isReached = false,
    result = null as boolean | null,
    accentColor = '#4f46e5',
  }: {
    stationType: StationType;
    x: number;
    y: number;
    index: number;
    isCurrent: boolean;
    isReached: boolean;
    result: boolean | null;
    accentColor: string;
  } = $props();

  const theme = $derived(getStationTheme(stationType));

  // ── Visual state ──
  const stateLabel = $derived(
    isCurrent ? 'active'
    : isReached && result === true ? 'correct'
    : isReached && result === false ? 'wrong'
    : isReached ? 'reached'
    : 'locked'
  );

  const radius = $derived(isCurrent ? 26 : 20);
  const strokeWidth = $derived(isCurrent ? 4 : 2.5);
  const fillOpacity = $derived(isReached && !isCurrent ? 0.6 : isCurrent ? 1 : 0.3);

  const fillColor = $derived(
    isCurrent ? accentColor
    : isReached && result === true ? '#22c55e'
    : isReached && result === false ? '#fbbf24'
    : '#cbd5e1'
  );

  const strokeColor = $derived(
    isCurrent ? accentColor
    : isReached && result === true ? '#16a34a'
    : isReached && result === false ? '#f59e0b'
    : '#94a3b8'
  );

  const textColor = $derived(isReached || isCurrent ? '#1e293b' : '#94a3b8');
</script>

<g class="station-group {isCurrent ? 'station-current' : ''}">
  <!-- Outer glow ring (current station only) -->
  {#if isCurrent}
    <circle cx={x} cy={y} r={radius + 8}
            fill="none" stroke={accentColor} stroke-width="2"
            opacity="0.3" class="animate-pulse" />
    <circle cx={x} cy={y} r={radius + 4}
            fill="none" stroke={accentColor} stroke-width="1.5"
            opacity="0.5" class="animate-ping-slow" />
  {/if}

  <!-- Main station circle -->
  <circle cx={x} cy={y} r={radius}
          fill={fillColor}
          stroke={strokeColor}
          stroke-width={strokeWidth}
          opacity={fillOpacity}
          class="station-circle" />

  <!-- Station emoji -->
  <text x={x} y={y + 1} text-anchor="middle" dominant-baseline="central"
        font-size={isCurrent ? '22' : '16'}
        opacity={isReached || isCurrent ? 1 : 0.5}
        class="select-none">{theme.emoji}</text>

  <!-- Result check / star on reached stations -->
  {#if isReached && !isCurrent}
    {#if result === true}
      <!-- Green checkmark badge -->
      <circle cx={x + radius - 4} cy={y - radius + 4} r="10" fill="#22c55e" stroke="white" stroke-width="2" />
      <text x={x + radius - 4} y={y - radius + 5} text-anchor="middle" dominant-baseline="central"
            font-size="12" fill="white" class="select-none">✓</text>
    {:else if result === false}
      <!-- Yellow star badge (encouraging, not X) -->
      <circle cx={x + radius - 4} cy={y - radius + 4} r="10" fill="#fbbf24" stroke="white" stroke-width="2" />
      <text x={x + radius - 4} y={y - radius + 5} text-anchor="middle" dominant-baseline="central"
            font-size="12" fill="white" class="select-none">⭐</text>
    {/if}
  {/if}

  <!-- Station number -->
  <text x={x} y={y + radius + 14} text-anchor="middle" dominant-baseline="central"
        font-size="10" fill={textColor} class="select-none font-medium">
    {index + 1}
  </text>

  <!-- Station label (current only) -->
  {#if isCurrent}
    <text x={x} y={y - radius - 14} text-anchor="middle" dominant-baseline="central"
          font-size="11" fill={accentColor} class="select-none font-bold">
      {theme.name}
    </text>
  {/if}
</g>

<style>
  @keyframes pingSlow {
    0% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(1.15); opacity: 0.2; }
    100% { transform: scale(1); opacity: 0.5; }
  }
  :global(.animate-ping-slow) {
    animation: pingSlow 2s ease-in-out infinite;
  }
  :global(.station-circle) {
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }
</style>
