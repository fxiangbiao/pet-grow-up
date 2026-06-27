<script lang="ts">
  import { onMount } from 'svelte';
  import { getInventory, useItem } from '$lib/api/shop';
  import type { UserItem, UseItemResult } from '$lib/types/api';
  import { toastStore } from '$lib/stores/toast.svelte';

  let {
    spiritId,
    onItemUsed
  }: {
    spiritId: number;
    onItemUsed?: (result: UseItemResult) => void;
  } = $props();

  let items = $state<UserItem[]>([]);
  let loading = $state(true);
  let using = $state<number | null>(null);
  let showSelector = $state(false);

  async function load() {
    loading = true;
    try {
      items = await getInventory();
    } catch {}
    loading = false;
  }

  async function handleUse(userItemId: number) {
    using = userItemId;
    try {
      const result = await useItem(userItemId, spiritId, 1);
      toastStore.success(`使用 ${result.itemName} 成功！`);
      // Reload inventory to update quantities
      items = await getInventory();
      if (onItemUsed) onItemUsed(result);
    } catch (e: any) {
      toastStore.error(e.message || '使用失败');
    } finally {
      using = null;
    }
  }

  onMount(load);

  const categoryIcons: Record<string, string> = {
    FOOD: '🍬',
    TOY: '🧸',
    DECORATION: '🎨',
    CONSUMABLE: '🧪'
  };
</script>

<div>
  <button
    onclick={() => { showSelector = !showSelector; if (showSelector) load(); }}
    class="px-3 py-2 text-sm bg-gradient-to-r from-green-400 to-emerald-500 text-white rounded-lg hover:from-green-500 hover:to-emerald-600 transition-all shadow-sm"
  >
    {showSelector ? '收起物品' : '🎒 使用物品'}
  </button>

  {#if showSelector}
    <div class="mt-3 bg-gray-50 rounded-xl p-3 border border-gray-100">
      {#if loading}
        <p class="text-sm text-gray-400">加载中...</p>
      {:else if items.length === 0}
        <p class="text-sm text-gray-400">背包空空，去商店购买物品吧</p>
      {:else}
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
          {#each items as item (item.id)}
            <button
              onclick={() => handleUse(item.id)}
              disabled={using === item.id}
              class="flex items-center gap-2 px-3 py-2 bg-white rounded-lg border border-gray-200 hover:border-green-300 hover:bg-green-50 transition disabled:opacity-50 text-left"
            >
              <span>{categoryIcons[item.itemDef.category] || '📦'}</span>
              <div class="min-w-0">
                <p class="text-xs font-medium text-gray-700 truncate">{item.itemDef.name}</p>
                <p class="text-xs text-gray-400">x{item.quantity}</p>
              </div>
            </button>
          {/each}
        </div>
      {/if}
    </div>
  {/if}
</div>
