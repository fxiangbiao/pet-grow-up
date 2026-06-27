<script lang="ts">
  import { toastStore } from '$lib/stores/toast.svelte';

  function getStyle(type: string): string {
    const map: Record<string, string> = {
      success: 'bg-green-500 text-white',
      error: 'bg-red-500 text-white',
      info: 'bg-blue-500 text-white'
    };
    return map[type] || map.info;
  }
</script>

{#if toastStore.toasts.length > 0}
  <div class="fixed top-4 left-1/2 -translate-x-1/2 z-50 flex flex-col gap-2 items-center">
    {#each toastStore.toasts as toast (toast.id)}
      <div class={['px-4 py-3 rounded-lg shadow-lg text-sm font-medium animate-slide-up', getStyle(toast.type)].join(' ')}>
        {toast.message}
      </div>
    {/each}
  </div>
{/if}
