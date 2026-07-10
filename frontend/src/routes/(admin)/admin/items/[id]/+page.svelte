<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi, type CreateItemDef } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { ITEM_CATEGORY_LABELS, EFFECT_TYPE_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);

  let formData = $state<CreateItemDef>({
    itemKey: '',
    name: '',
    description: '',
    category: 'FOOD',
    effectType: '',
    effectValue: 0,
    price: 0,
    iconUrl: '',
    isConsumable: true,
    isPurchasable: true,
    displayOrder: 0,
  });

  onMount(() => {
    if (!isNew) loadItem();
    else loading = false;
  });

  async function loadItem() {
    loading = true;
    try {
      const data = await adminApi.getItem(itemId);
      formData = {
        itemKey: data.itemKey,
        name: data.name,
        description: data.description || '',
        category: data.category,
        effectType: data.effectType || '',
        effectValue: data.effectValue,
        price: data.price,
        iconUrl: data.iconUrl || '',
        isConsumable: data.isConsumable,
        isPurchasable: data.isPurchasable,
        displayOrder: data.displayOrder,
      };
    } catch (e: any) {
      toastStore.error(e.message || '加载失败');
      goto('/admin/items');
    } finally {
      loading = false;
    }
  }

  async function handleSave() {
    if (!formData.itemKey?.trim()) { toastStore.error('商品标识不能为空'); return; }
    if (!formData.name?.trim()) { toastStore.error('商品名称不能为空'); return; }
    if (!formData.category?.trim()) { toastStore.error('商品分类不能为空'); return; }

    saving = true;
    try {
      const payload = { ...formData, effectType: formData.effectType || undefined };
      if (isNew) {
        await adminApi.createItem(payload);
        toastStore.success('商品已创建');
        goto('/admin/items');
      } else {
        await adminApi.updateItem(itemId, payload);
        toastStore.success('商品已保存');
      }
    } catch (e: any) {
      toastStore.error(e.message || '保存失败');
    } finally {
      saving = false;
    }
  }

  async function handleDelete() {
    try {
      await adminApi.deleteItem(itemId);
      toastStore.success('商品已删除');
      goto('/admin/items');
    } catch (e: any) {
      toastStore.error(e.message || '删除失败');
    } finally {
      showDeleteModal = false;
    }
  }
</script>

<div>
  <!-- Header -->
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/items')}
              class="text-gray-500 hover:text-gray-700 text-sm">← 返回商品列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建商品' : '编辑商品 #' + itemId}</h2>
    </div>
    <div class="flex gap-2">
      {#if !isNew}
        <button onclick={() => showDeleteModal = true}
                class="px-4 py-2 bg-red-50 text-red-600 text-sm rounded-lg hover:bg-red-100 transition border border-red-200">
          删除
        </button>
      {/if}
      <button onclick={handleSave} disabled={saving}
              class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition disabled:opacity-40">
        {saving ? '保存中...' : '保存'}
      </button>
    </div>
  </div>

  {#if loading}
    <div class="text-center text-gray-400 py-12">加载中...</div>
  {:else}
    <!-- Form -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 max-w-2xl space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm text-gray-500 mb-1">商品标识 *</label>
          <input type="text" bind:value={formData.itemKey} disabled={!isNew}
                 class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50 disabled:text-gray-400"
                 placeholder="如 energy_candy" />
        </div>
        <div>
          <label class="block text-sm text-gray-500 mb-1">商品名称 *</label>
          <input type="text" bind:value={formData.name}
                 class="w-full px-3 py-2 border rounded-lg text-sm" placeholder="如 能量糖" />
        </div>
      </div>

      <div>
        <label class="block text-sm text-gray-500 mb-1">描述</label>
        <textarea bind:value={formData.description} rows="2"
                  class="w-full px-3 py-2 border rounded-lg text-sm" placeholder="商品描述"></textarea>
      </div>

      <div class="grid grid-cols-3 gap-4">
        <div>
          <label class="block text-sm text-gray-500 mb-1">分类 *</label>
          <select bind:value={formData.category} class="w-full px-3 py-2 border rounded-lg text-sm">
            {#each Object.entries(ITEM_CATEGORY_LABELS) as [key, label]}
              <option value={key}>{label}</option>
            {/each}
          </select>
        </div>
        <div>
          <label class="block text-sm text-gray-500 mb-1">效果类型</label>
          <select bind:value={formData.effectType} class="w-full px-3 py-2 border rounded-lg text-sm">
            <option value="">无</option>
            {#each Object.entries(EFFECT_TYPE_LABELS) as [key, label]}
              <option value={key}>{label}</option>
            {/each}
          </select>
        </div>
        <div>
          <label class="block text-sm text-gray-500 mb-1">效果值</label>
          <input type="number" bind:value={formData.effectValue}
                 class="w-full px-3 py-2 border rounded-lg text-sm" />
        </div>
      </div>

      <div class="grid grid-cols-3 gap-4">
        <div>
          <label class="block text-sm text-gray-500 mb-1">价格 (⚡)</label>
          <input type="number" bind:value={formData.price}
                 class="w-full px-3 py-2 border rounded-lg text-sm" />
        </div>
        <div>
          <label class="block text-sm text-gray-500 mb-1">图标 (emoji/url)</label>
          <input type="text" bind:value={formData.iconUrl}
                 class="w-full px-3 py-2 border rounded-lg text-sm" placeholder="🍬" />
        </div>
        <div>
          <label class="block text-sm text-gray-500 mb-1">排序</label>
          <input type="number" bind:value={formData.displayOrder}
                 class="w-full px-3 py-2 border rounded-lg text-sm" />
        </div>
      </div>

      <div class="flex gap-6 pt-2">
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" bind:checked={formData.isConsumable} class="rounded" />
          可消耗
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" bind:checked={formData.isPurchasable} class="rounded" />
          可购买
        </label>
      </div>
    </div>
  {/if}
</div>

<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除"
              message="确定要删除该商品吗？如果已有用户持有将无法删除。"
              onConfirm={handleDelete}
              onCancel={() => showDeleteModal = false} />
