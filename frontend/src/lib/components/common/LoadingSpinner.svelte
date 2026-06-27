<script lang="ts">
  let { size = 'md', text = '加载中...' }: { size?: 'sm' | 'md' | 'lg'; text?: string } = $props();

  const sizeClasses: Record<string, string> = {
    sm: 'w-5 h-5',
    md: 'w-8 h-8',
    lg: 'w-12 h-12'
  };
</script>

<div class="flex flex-col items-center justify-center py-8 gap-3">
  <div class={['animate-spin rounded-full border-2 border-gray-200 border-t-indigo-500', sizeClasses[size]].join(' ')}></div>
  {#if text}
    <p class="text-sm text-gray-400">{text}</p>
  {/if}
</div>
