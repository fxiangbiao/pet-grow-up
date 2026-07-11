<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { ACHIEVEMENT_CATEGORY_LABELS, ACHIEVEMENT_RARITY_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({
    achievementKey: '', name: '', description: '', iconUrl: '', category: 'STUDY', rarity: 'COMMON',
    requirementType: '', requirementThreshold: 1, subject: '', rewardEnergy: 0, rewardItemKey: '', rewardTitle: '', displayOrder: 0, isHidden: false
  });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getAchievement(itemId);
      formData = { achievementKey: d.achievementKey, name: d.name, description: d.description||'', iconUrl: d.iconUrl||'',
        category: d.category, rarity: d.rarity, requirementType: d.requirementType, requirementThreshold: d.requirementThreshold,
        subject: d.subject||'', rewardEnergy: d.rewardEnergy||0, rewardItemKey: d.rewardItemKey||'',
        rewardTitle: d.rewardTitle||'', displayOrder: d.displayOrder||0, isHidden: d.isHidden||false };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/achievements'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.achievementKey?.trim()) { toastStore.error('成就标识不能为空'); return; }
    if (!formData.name?.trim()) { toastStore.error('成就名称不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createAchievement(formData); toastStore.success('成就已创建'); goto('/admin/achievements'); }
      else { await adminApi.updateAchievement(itemId, formData); toastStore.success('成就已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteAchievement(itemId); toastStore.success('成就已删除'); goto('/admin/achievements'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/achievements')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回成就列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建成就' : '编辑成就 #' + itemId}</h2>
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
        <div><label class="block text-sm text-gray-500 mb-1">成就标识 *</label><input type="text" bind:value={formData.achievementKey} disabled={!isNew} class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">名称 *</label><input type="text" bind:value={formData.name} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">描述</label><textarea bind:value={formData.description} rows="2" class="w-full px-3 py-2 border rounded-lg text-sm"></textarea></div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">分类</label><select bind:value={formData.category} class="w-full px-3 py-2 border rounded-lg text-sm">{#each Object.entries(ACHIEVEMENT_CATEGORY_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
        <div><label class="block text-sm text-gray-500 mb-1">稀有度</label><select bind:value={formData.rarity} class="w-full px-3 py-2 border rounded-lg text-sm">{#each Object.entries(ACHIEVEMENT_RARITY_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
        <div><label class="block text-sm text-gray-500 mb-1">学科</label><select bind:value={formData.subject} class="w-full px-3 py-2 border rounded-lg text-sm"><option value="">无</option><option value="math">数学</option><option value="chinese">语文</option><option value="english">英语</option></select></div>
      </div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">条件类型</label><input type="text" bind:value={formData.requirementType} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">条件阈值</label><input type="number" bind:value={formData.requirementThreshold} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励精力⚡</label><input type="number" bind:value={formData.rewardEnergy} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">奖励道具</label><input type="text" bind:value={formData.rewardItemKey} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励称号</label><input type="text" bind:value={formData.rewardTitle} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">排序</label><input type="number" bind:value={formData.displayOrder} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <label class="flex items-center gap-2 text-sm"><input type="checkbox" bind:checked={formData.isHidden} class="rounded" /> 隐藏成就</label>
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该成就吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
