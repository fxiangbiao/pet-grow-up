<script lang="ts">
  import { onMount } from 'svelte';
  import { getInventory } from '$lib/api/shop';
  import type { UserItem } from '$lib/types/api';
  import LoadingSpinner from '$lib/components/common/LoadingSpinner.svelte';
  import EmptyState from '$lib/components/common/EmptyState.svelte';

  let items = $state<UserItem[]>([]);
  let loading = $state(true);

  async function load() {
    loading = true;
    try {
      items = await getInventory();
    } catch {}
    loading = false;
  }

  onMount(load);

  const categoryIcons: Record<string, string> = {
    FOOD: '🍬',
    TOY: '🧸',
    DECORATION: '🎨',
    CONSUMABLE: '🧪'
  };
</script>

<div class="bg-white rounded-2xl shadow-sm p-4">
  <h2 class="text-sm font-semibold text-gray-700 mb-3">我的背包</h2>

  {#if loading}
    <LoadingSpinner size="sm" text="加载背包..." />
  {:else if items.length === 0}
    <EmptyState icon="🎒" title="背包空空" message="去商店购买一些物品吧！" />
  {:else}
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
      {#each items as item (item.id)}
        <div class="bg-gray-50 rounded-xl p-3 border border-gray-100">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xl">{categoryIcons[item.itemDef.category] || '📦'}</span>
            <span class="text-xs font-bold text-indigo-500">x{item.quantity}</span>
          </div>
          <p class="text-sm font-medium text-gray-700">{item.itemDef.name}</p>
          <p class="text-xs text-gray-400">+{item.itemDef.effectValue} {item.itemDef.effectType}</p>
        </div>
      {/each}
    </div>
  {/if}
</div>
