<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { REWARD_TYPE_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({ rewardKey: '', name: '', rewardType: 'ENERGY', rewardValue: 0, rewardItemKey: '', unlockDay: 1 });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getDailyReward(itemId);
      formData = { rewardKey: d.rewardKey, name: d.name, rewardType: d.rewardType, rewardValue: d.rewardValue, rewardItemKey: d.rewardItemKey||'', unlockDay: d.unlockDay||1 };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/daily-rewards'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.rewardKey?.trim()) { toastStore.error('奖励标识不能为空'); return; }
    if (!formData.name?.trim()) { toastStore.error('奖励名称不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createDailyReward(formData); toastStore.success('奖励已创建'); goto('/admin/daily-rewards'); }
      else { await adminApi.updateDailyReward(itemId, formData); toastStore.success('奖励已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteDailyReward(itemId); toastStore.success('奖励已删除'); goto('/admin/daily-rewards'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/daily-rewards')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回奖励列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建奖励' : '编辑奖励 #' + itemId}</h2>
    </div>
    <div class="flex gap-2">
      {#if !isNew}<button onclick={() => showDeleteModal = true} class="px-4 py-2 bg-red-50 text-red-600 text-sm rounded-lg hover:bg-red-100 transition border border-red-200">删除</button>{/if}
      <button onclick={handleSave} disabled={saving} class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition disabled:opacity-40">{saving ? '保存中...' : '保存'}</button>
    </div>
  </div>
  {#if loading}<div class="text-center text-gray-400 py-12">加载中...</div>
  {:else}
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 max-w-2xl space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">奖励标识 *</label><input type="text" bind:value={formData.rewardKey} disabled={!isNew} class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">名称 *</label><input type="text" bind:value={formData.name} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">奖励类型</label><select bind:value={formData.rewardType} class="w-full px-3 py-2 border rounded-lg text-sm">{#each Object.entries(REWARD_TYPE_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励值</label><input type="number" bind:value={formData.rewardValue} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">解锁天数</label><input type="number" bind:value={formData.unlockDay} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      {#if formData.rewardType === 'ITEM'}
      <div><label class="block text-sm text-gray-500 mb-1">奖励道具Key</label><input type="text" bind:value={formData.rewardItemKey} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      {/if}
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该奖励吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
