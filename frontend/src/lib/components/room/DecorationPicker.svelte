<script lang="ts">
  import type { PlacedItem } from '$lib/api/pet-room';

  let {
    items = [],
    show = false,
    onselect,
    onclose,
  }: {
    items: PlacedItem[];
    show?: boolean;
    onselect?: (item: PlacedItem) => void;
    onclose?: () => void;
  } = $props();
</script>

{#if show}
  <div class="fixed inset-0 z-40 flex items-end justify-center bg-black/20"
       role="dialog" onclick={onclose}>
    <div class="bg-white rounded-t-2xl shadow-xl p-5 w-full max-w-md animate-slide-up"
         onclick={(e: Event) => e.stopPropagation()}>
      <div class="flex items-center justify-between mb-3">
        <h3 class="font-semibold text-gray-800">选择装饰品放置</h3>
        <button onclick={onclose} class="text-gray-400 hover:text-gray-600 text-lg">✕</button>
      </div>

      {#if items.length === 0}
        <p class="text-sm text-gray-400 text-center py-8">背包中没有装饰品，去商店购买吧！</p>
      {:else}
        <div class="grid grid-cols-4 gap-3 max-h-64 overflow-y-auto">
          {#each items as item (item.itemKey)}
            <button onclick={() => onselect?.(item)}
                    class="p-3 rounded-xl bg-gray-50 hover:bg-indigo-50 hover:shadow-sm transition text-center">
              <div class="text-2xl mb-1">{item.iconUrl || '📦'}</div>
              <div class="text-xs text-gray-600 truncate">{item.name}</div>
            </button>
          {/each}
        </div>
      {/if}
    </div>
  </div>
{/if}
