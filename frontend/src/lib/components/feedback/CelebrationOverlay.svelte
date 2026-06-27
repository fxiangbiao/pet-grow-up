<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';
  import ParticleEffect from './ParticleEffect.svelte';

  let { show = true }: { show?: boolean } = $props();

  $effect(() => {
    if (show) {
      soundManager.playCelebrate();
    }
  });
</script>

{#if show}
  <ParticleEffect emojis={['🌟', '✨', '🎉', '🎊', '⭐', '💫']} count={16} spread={90} />
  <div class="fixed inset-0 pointer-events-none z-50 flex items-center justify-center">
    <div class="text-6xl animate-celebration">🎉</div>
  </div>
{/if}
