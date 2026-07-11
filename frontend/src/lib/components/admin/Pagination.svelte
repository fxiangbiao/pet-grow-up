<script lang="ts">
  let {
    page,
    totalPages,
    total,
    goPage,
  }: {
    page: number;
    totalPages: number;
    total: number;
    goPage: (p: number) => void;
  } = $props();
</script>

{#if totalPages > 1}
  <div class="flex items-center justify-between px-4 py-3 border-t">
    <span class="text-sm text-gray-500">共 {total} 条，第 {page}/{totalPages} 页</span>
    <div class="flex gap-1">
      <button disabled={page === 1} onclick={() => goPage(page - 1)}
              class="px-2 py-1 text-sm border rounded hover:bg-gray-50 disabled:opacity-30">‹</button>
      {#each Array.from({ length: totalPages }, (_, i) => i + 1) as p}
        {#if p === 1 || p === totalPages || Math.abs(p - page) <= 2}
          <button onclick={() => goPage(p)}
                  class="px-2 py-1 text-sm border rounded {p === page ? 'bg-indigo-600 text-white' : 'hover:bg-gray-50'}">{p}</button>
        {:else if p === 2 || p === totalPages - 1}
          <span class="px-2 py-1 text-sm text-gray-400">...</span>
        {/if}
      {/each}
      <button disabled={page === totalPages} onclick={() => goPage(page + 1)}
              class="px-2 py-1 text-sm border rounded hover:bg-gray-50 disabled:opacity-30">›</button>
    </div>
  </div>
{/if}
