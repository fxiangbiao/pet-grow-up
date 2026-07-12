<script lang="ts">
  let {
    title = '暂无内容',
    message = '',
    icon = '📭',
    actionLabel = '',
    onAction
  }: {
    title?: string;
    message?: string;
    icon?: string;
    actionLabel?: string;
    onAction?: () => void;
  } = $props();
</script>

<div class="flex flex-col items-center justify-center py-12 text-center">
  <div class="text-5xl mb-4 opacity-60">{icon}</div>
  <h3 class="text-lg font-medium text-gray-500 mb-1">{title}</h3>
  {#if message}
    <p class="text-sm text-gray-400 mb-4">{message}</p>
  {/if}
  {#if onAction && actionLabel}
    <button
      onclick={onAction}
      class="px-6 py-2.5 bg-indigo-500 text-white rounded-xl text-sm font-medium hover:bg-indigo-600 transition shadow-sm"
    >
      {actionLabel}
    </button>
  {/if}
</div>