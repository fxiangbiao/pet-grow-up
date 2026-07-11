<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { EVENT_TYPE_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({ eventKey: '', eventType: 'BONUS_ENERGY', triggerChance: 10, minAccuracy: 0, minStreak: 0, rewardEnergy: 0, rewardAffection: 0, displayText: '' });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getEvent(itemId);
      formData = { eventKey: d.eventKey, eventType: d.eventType, triggerChance: d.triggerChance||10, minAccuracy: d.minAccuracy||0, minStreak: d.minStreak||0, rewardEnergy: d.rewardEnergy||0, rewardAffection: d.rewardAffection||0, displayText: d.displayText||'' };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/events'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.eventKey?.trim()) { toastStore.error('事件标识不能为空'); return; }
    if (!formData.eventType?.trim()) { toastStore.error('事件类型不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createEvent(formData); toastStore.success('事件已创建'); goto('/admin/events'); }
      else { await adminApi.updateEvent(itemId, formData); toastStore.success('事件已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteEvent(itemId); toastStore.success('事件已删除'); goto('/admin/events'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/events')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回事件列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建事件' : '编辑事件 #' + itemId}</h2>
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
        <div><label class="block text-sm text-gray-500 mb-1">事件标识 *</label><input type="text" bind:value={formData.eventKey} disabled={!isNew} class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">事件类型 *</label><select bind:value={formData.eventType} class="w-full px-3 py-2 border rounded-lg text-sm">{#each Object.entries(EVENT_TYPE_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
      </div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">触发概率(%)</label><input type="number" step="0.1" bind:value={formData.triggerChance} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">最低准确率(%)</label><input type="number" step="0.1" bind:value={formData.minAccuracy} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">最低连击</label><input type="number" bind:value={formData.minStreak} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div class="grid grid-cols-2 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">奖励精力⚡</label><input type="number" bind:value={formData.rewardEnergy} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励亲密度</label><input type="number" bind:value={formData.rewardAffection} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">展示文本</label><textarea bind:value={formData.displayText} rows="2" class="w-full px-3 py-2 border rounded-lg text-sm"></textarea></div>
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该事件吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
