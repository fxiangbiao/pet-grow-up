<script lang="ts">
  let {
    value = 0,
    isPlayerDamage = false,
    x = 0,
    y = 0,
    critical = false
  }: {
    value?: number;
    isPlayerDamage?: boolean;
    x?: number;
    y?: number;
    critical?: boolean;
  } = $props();

  const color = $derived(isPlayerDamage ? 'text-red-500' : 'text-amber-400');
  const sign = $derived(isPlayerDamage ? '-' : '+');
  const size = $derived(critical ? 'text-3xl' : value >= 80 ? 'text-2xl' : 'text-xl');
  const drift = $derived((Math.random() - 0.5) * 30);
</script>

<div
  class="pointer-events-none fixed z-50 font-black animate-float-damage {color} {size}"
  style="left: calc(50% + {x + drift}px); top: calc(40% + {y}px); text-shadow: 0 0 8px currentColor;"
>
  {#if critical}
    💥 {sign}{Math.abs(value)}
  {:else}
    {sign}{Math.abs(value)}
  {/if}
</div>
