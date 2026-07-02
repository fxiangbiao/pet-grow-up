<script lang="ts">
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    positionX = 0,
    positionY = 0,
    isAnimating = false,
    species = null as SpiritSpecies | null,
    evolutionStage = 1,
    mood = 'idle' as 'idle' | 'happy' | 'excited' | 'hurt',
    accentColor = '#4f46e5',
    onArrived = () => {},
  }: {
    positionX: number;
    positionY: number;
    isAnimating: boolean;
    species: SpiritSpecies | null;
    evolutionStage: number;
    mood: 'idle' | 'happy' | 'excited' | 'hurt';
    accentColor: string;
    onArrived?: () => void;
  } = $props();

  // ── Track animation completion ──
  let prevAnimating = $state(false);
  $effect(() => {
    if (prevAnimating && !isAnimating) {
      // Animation just completed — slight delay then notify
      setTimeout(() => onArrived(), 200);
    }
    prevAnimating = isAnimating;
  });

  const tokenSize = 36;
  const halfToken = tokenSize / 2;
</script>

<g
  class="map-token {isAnimating ? 'token-moving' : 'token-idle'}"
  style="transform: translate({positionX - halfToken}px, {positionY - halfToken}px);"
>
  <!-- Shadow ellipse -->
  <ellipse cx={halfToken} cy={tokenSize + 2} rx="16" ry="4"
           fill="rgba(0,0,0,0.15)" class="token-shadow" />

  <!-- Spirit avatar circle -->
  {#if species}
    <foreignObject x="0" y="0" width={tokenSize} height={tokenSize}>
      <div class="w-full h-full rounded-full overflow-hidden border-2"
           style="border-color: {accentColor}; box-shadow: 0 0 8px {accentColor}40;">
        <SpiritAvatar {species} {evolutionStage} {mood} size="sm" />
      </div>
    </foreignObject>
  {:else}
    <!-- Fallback: colored circle with emoji -->
    <circle cx={halfToken} cy={halfToken} r={halfToken}
            fill={accentColor} opacity="0.3" />
    <text x={halfToken} y={halfToken + 1} text-anchor="middle" dominant-baseline="central"
          font-size="16" class="select-none">🐾</text>
  {/if}

  <!-- Glow ring -->
  <circle cx={halfToken} cy={halfToken} r={halfToken + 2}
          fill="none" stroke={accentColor} stroke-width="2"
          opacity={isAnimating ? 0.8 : 0.4}
          class="token-glow" />
</g>

<style>
  :global(.map-token) {
    transition: transform 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
    will-change: transform;
  }
  :global(.token-idle) {
    animation: tokenBounce 2s ease-in-out infinite;
  }
  :global(.token-moving) {
    animation: none;
  }
  :global(.token-shadow) {
    transition: all 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  :global(.token-glow) {
    transition: opacity 0.3s ease;
  }
  @keyframes tokenBounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-4px); }
  }
</style>
