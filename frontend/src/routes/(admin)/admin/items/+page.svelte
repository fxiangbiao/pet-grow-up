<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { adminApi, type ItemFilter, type ItemPage } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { ITEM_CATEGORY_LABELS, EFFECT_TYPE_LABELS } from '$lib/components/admin/constants';
  import Pagination from '$lib/components/admin/Pagination.svelte';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let filter = $state<ItemFilter>({ page: 1, size: 20 });
  let pageData = $state<ItemPage | null>(null);
  let loading = $state(false);
  let errorMsg = $state<string | null>(null);
  let confirmDelete = $state<number | null>(null);

  onMount(() => { loadItems(); });

  async function loadItems() {
    loading = true;
    errorMsg = null;
    try {
      pageData = await adminApi.listItems(filter);
    } catch (e: any) {
      errorMsg = e.message || '加载失败';
      pageData = null;
    } finally {
      loading = false;
    }
  }

  function applyFilter(updates: Partial<ItemFilter>) {
    filter = { ...filter, ...updates, page: 1 };
    loadItems();
  }

  function goPage(p: number) {
    filter = { ...filter, page: p };
    loadItems();
  }

  async function handleDelete(id: number) {
    try {
      await adminApi.deleteItem(id);
      toastStore.success('商品已删除');
      confirmDelete = null;
      loadItems();
    } catch (e: any) { toastStore.error(e.message || '删除失败'); }
  }

  let totalPages = $derived(pageData ? Math.ceil(pageData.total / pageData.size) : 0);
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">🛒 商品管理</h2>
    <button onclick={() => goto('/admin/items/new')}
            class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition">
      ➕ 新建商品
    </button>
  </div>

  <!-- Filters -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4">
    <div class="flex gap-3">
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => applyFilter({ category: (e.target as HTMLSelectElement).value || undefined })}>
        <option value="">全部分类</option>
        {#each Object.entries(ITEM_CATEGORY_LABELS) as [key, label]}
          <option value={key}>{label}</option>
        {/each}
      </select>
      <input type="text" placeholder="搜索名称/标识..." class="px-3 py-1.5 border rounded-lg text-sm flex-1"
             onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') applyFilter({ keyword: (e.target as HTMLInputElement).value || undefined }); }}/>
    </div>
  </div>

  <!-- Table -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
    {#if loading}
      <div class="text-center text-gray-400 py-12">加载中...</div>
    {:else if pageData && pageData.items.length > 0}
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b">
          <tr>
            <th class="text-left px-4 py-2 font-medium text-gray-500 w-12">ID</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">图标</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">名称</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">标识</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">分类</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">效果</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">价格</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">可购</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">排序</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">操作</th>
          </tr>
        </thead>
        <tbody class="divide-y">
          {#each pageData.items as item}
            <tr class="hover:bg-gray-50">
              <td class="px-4 py-2 text-gray-400">{item.id}</td>
              <td class="px-4 py-2 text-xl text-center">{item.iconUrl || '📦'}</td>
              <td class="px-4 py-2 font-medium">{item.name}</td>
              <td class="px-4 py-2 text-xs text-gray-500 font-mono">{item.itemKey}</td>
              <td class="px-4 py-2">
                <span class="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">
                  {ITEM_CATEGORY_LABELS[item.category] || item.category}
                </span>
              </td>
              <td class="px-4 py-2 text-xs">
                {item.effectType ? `${EFFECT_TYPE_LABELS[item.effectType] || item.effectType} +${item.effectValue}` : '-'}
              </td>
              <td class="px-4 py-2 text-center text-xs">⚡{item.price}</td>
              <td class="px-4 py-2 text-center">
                {item.isPurchasable ? '✅' : '❌'}
              </td>
              <td class="px-4 py-2 text-center text-xs text-gray-400">{item.displayOrder}</td>
              <td class="px-4 py-2 text-center">
                <button onclick={() => goto(`/admin/items/${item.id}`)}
                        class="text-indigo-600 hover:text-indigo-800 text-xs mr-2">编辑</button>
                <button onclick={() => confirmDelete = item.id}
                        class="text-red-500 hover:text-red-700 text-xs">删除</button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
      <Pagination page={filter.page ?? 1} totalPages={totalPages} total={pageData.total} {goPage} />
    {:else if errorMsg}
      <div class="text-center py-12 px-4">
        <div class="text-red-500 text-sm bg-red-50 rounded-lg p-4 inline-block max-w-lg">{errorMsg}</div>
      </div>
    {:else}
      <div class="text-center text-gray-400 py-12">暂无商品</div>
    {/if}
  </div>
</div>

<ConfirmModal show={confirmDelete !== null} title="确认删除" confirmText="删除"
              message="确定要删除该商品吗？如果已有用户持有将无法删除。"
              onConfirm={() => confirmDelete !== null && handleDelete(confirmDelete)}
              onCancel={() => confirmDelete = null} />
