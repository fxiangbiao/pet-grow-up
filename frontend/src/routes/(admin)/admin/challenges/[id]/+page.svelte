<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { CHALLENGE_TYPE_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({ challengeType: 'STUDY_SESSION', description: '', targetValue: 1, rewardEnergy: 0, iconUrl: '' });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getChallenge(itemId);
      formData = { challengeType: d.challengeType, description: d.description, targetValue: d.targetValue, rewardEnergy: d.rewardEnergy||0, iconUrl: d.iconUrl||'' };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/challenges'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.challengeType?.trim()) { toastStore.error('挑战类型不能为空'); return; }
    if (!formData.description?.trim()) { toastStore.error('描述不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createChallenge(formData); toastStore.success('挑战已创建'); goto('/admin/challenges'); }
      else { await adminApi.updateChallenge(itemId, formData); toastStore.success('挑战已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteChallenge(itemId); toastStore.success('挑战已删除'); goto('/admin/challenges'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/challenges')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回挑战列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建挑战' : '编辑挑战 #' + itemId}</h2>
    </div>
    <div class="flex gap-2">
      {#if !isNew}<button onclick={() => showDeleteModal = true} class="px-4 py-2 bg-red-50 text-red-600 text-sm rounded-lg hover:bg-red-100 transition border border-red-200">删除</button>{/if}
      <button onclick={handleSave} disabled={saving} class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition disabled:opacity-40">{saving ? '保存中...' : '保存'}</button>
    </div>
  </div>
  {#if loading}<div class="text-center text-gray-400 py-12">加载中...</div>
  {:else}
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 max-w-2xl space-y-4">
      <div><label class="block text-sm text-gray-500 mb-1">挑战类型 *</label><select bind:value={formData.challengeType} disabled={!isNew} class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50">{#each Object.entries(CHALLENGE_TYPE_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
      <div><label class="block text-sm text-gray-500 mb-1">描述 *</label><textarea bind:value={formData.description} rows="2" class="w-full px-3 py-2 border rounded-lg text-sm"></textarea></div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">目标值</label><input type="number" bind:value={formData.targetValue} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励精力⚡</label><input type="number" bind:value={formData.rewardEnergy} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">图标</label><input type="text" bind:value={formData.iconUrl} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该挑战吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
