<script lang="ts">
  let {
    type = 'rect',
    width = '100%',
    height = '1rem',
    lines = 1,
    rounded = 'rounded-lg',
    className = ''
  }: {
    type?: 'text' | 'circle' | 'rect' | 'card';
    width?: string;
    height?: string;
    lines?: number;
    rounded?: string;
    className?: string;
  } = $props();
</script>

{#if type === 'text'}
  <div class="space-y-2 {className}" style="width: {width}">
    {#each Array(lines) as _, i}
      <div class="shimmer h-4 {rounded} bg-gray-200"
           style="width: {i === lines - 1 ? '70%' : '100%'}; height: {height};"></div>
    {/each}
  </div>
{:else if type === 'circle'}
  <div class="shimmer rounded-full bg-gray-200 {className}"
       style="width: {width}; height: {width};"></div>
{:else if type === 'card'}
  <div class="shimmer bg-gray-200 {rounded} {className}"
       style="width: {width}; height: {height};"></div>
{:else}
  <div class="shimmer bg-gray-200 {rounded} {className}"
       style="width: {width}; height: {height};"></div>
{/if}

<style>
  .shimmer {
    background-image: linear-gradient(
      90deg,
      rgba(255, 255, 255, 0) 0%,
      rgba(255, 255, 255, 0.4) 50%,
      rgba(255, 255, 255, 0) 100%
    );
    background-size: 200% 100%;
    animation: shimmer 1.5s ease-in-out infinite;
  }
  @keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }
</style>