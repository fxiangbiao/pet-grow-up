<script lang="ts">
  import { onMount } from 'svelte';
  import { getShopItems, buyItem } from '$lib/api/shop';
  import type { ItemDef } from '$lib/types/api';
  import ItemCard from '$lib/components/shop/ItemCard.svelte';
  import InventoryPanel from '$lib/components/shop/InventoryPanel.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { authStore } from '$lib/stores/auth.svelte';
  import LoadingSpinner from '$lib/components/common/LoadingSpinner.svelte';

  const tabs = [
    { key: 'shop', label: '商品列表', icon: '🛒' },
    { key: 'inventory', label: '我的背包', icon: '🎒' }
  ];

  const categoryTabs = [
    { key: '', label: '全部' },
    { key: 'FOOD', label: '食物' },
    { key: 'TOY', label: '玩具' },
  ];

  let activeTab = $state('shop');
  let activeCategory = $state('');
  let items = $state<ItemDef[]>([]);
  let loading = $state(true);

  async function loadShop() {
    loading = true;
    try {
      items = await getShopItems(activeCategory || undefined);
    } catch {}
    loading = false;
  }

  function switchCategory(category: string) {
    activeCategory = category;
    loadShop();
  }

  async function handleBuy(item: ItemDef) {
    try {
      await buyItem(item.id, 1);
      toastStore.success(`购买 ${item.name} 成功！消耗 ⚡${item.price}`);
      authStore.refreshProfile();
    } catch (e: any) {
      toastStore.error(e.message || '购买失败');
    }
  }

  onMount(loadShop);
</script>

<svelte:head>
  <title>商店 - Pet Grow Up</title>
</svelte:head>

<div class="space-y-6 animate-slide-up">
  <div class="bg-white rounded-2xl shadow-sm p-6">
    <h1 class="text-2xl font-bold text-gray-800">商店</h1>
    <p class="text-gray-500 mt-1">使用能量购买物品，帮助精灵成长！</p>
  </div>

  <div class="flex gap-2">
    {#each tabs as tab}
      <button
        onclick={() => activeTab = tab.key}
        class="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition
          {activeTab === tab.key
            ? 'bg-indigo-100 text-indigo-700 shadow-sm'
            : 'bg-white text-gray-500 hover:bg-gray-50'}"
      >
        <span>{tab.icon}</span>
        {tab.label}
      </button>
    {/each}
  </div>

  {#if activeTab === 'shop'}
    <!-- Category filter -->
    <div class="flex gap-2">
      {#each categoryTabs as ct}
        <button
          onclick={() => switchCategory(ct.key)}
          class="px-3 py-1.5 text-xs rounded-lg transition
            {activeCategory === ct.key
              ? 'bg-amber-100 text-amber-700'
              : 'bg-white text-gray-500 hover:bg-gray-50'}"
        >
          {ct.label}
        </button>
      {/each}
    </div>

    {#if loading}
      <LoadingSpinner size="md" text="加载商品..." />
    {:else if items.length === 0}
      <div class="text-center py-12 text-gray-400">暂无商品</div>
    {:else}
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {#each items as item (item.id)}
          <ItemCard {item} onBuy={handleBuy} />
        {/each}
      </div>
    {/if}

  {:else if activeTab === 'inventory'}
    <InventoryPanel />
  {/if}
</div>
