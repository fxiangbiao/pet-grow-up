<script lang="ts">
  let {
    emojis = ['✨', '⭐', '🌟'],
    count = 8,
    duration = 2000,
    spread = 80,
    active = true
  }: {
    emojis?: string[];
    count?: number;
    duration?: number;
    spread?: number;
    active?: boolean;
  } = $props();

  let particles = $derived.by(() => {
    if (!active) return [];
    return Array.from({ length: count }, (_, i) => ({
      id: i,
      emoji: emojis[i % emojis.length],
      x: 10 + Math.random() * spread,
      delay: Math.random() * 0.3,
      size: 16 + Math.random() * 16,
    }));
  });
</script>

{#if active}
  <div class="fixed inset-0 pointer-events-none z-50 overflow-hidden">
    {#each particles as p (p.id)}
      <div
        class="absolute animate-particle-float"
        style="left: {p.x}%; bottom: 30%; font-size: {p.size}px; animation-delay: {p.delay}s; animation-duration: {duration / 1000}s;"
      >
        {p.emoji}
      </div>
    {/each}
  </div>
{/if}

<style>
  @keyframes particle-float {
    0% { opacity: 1; transform: translateY(0) scale(0.5); }
    50% { opacity: 0.9; transform: translateY(-60px) scale(1.2); }
    100% { opacity: 0; transform: translateY(-120px) scale(0.8); }
  }
  :global(.animate-particle-float) {
    animation: particle-float ease-out forwards;
  }
</style>
