<script lang="ts">
  let { title = '暂无内容', message = '', icon = '📭' }: { title?: string; message?: string; icon?: string } = $props();
</script>

<div class="flex flex-col items-center justify-center py-12 text-center">
  <div class="text-5xl mb-4 opacity-60">{icon}</div>
  <h3 class="text-lg font-medium text-gray-500 mb-1">{title}</h3>
  {#if message}
    <p class="text-sm text-gray-400">{message}</p>
  {/if}
</div>
