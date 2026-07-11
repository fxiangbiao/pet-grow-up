<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({ chapterNumber: 1, title: '', narrative: '', npcName: '', npcDialogue: '', choiceText: '', requirementType: '', requirementValue: 1, rewardEnergy: 0, displayOrder: 0 });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getStory(itemId);
      formData = { chapterNumber: d.chapterNumber, title: d.title, narrative: d.narrative||'', npcName: d.npcName||'', npcDialogue: d.npcDialogue||'', choiceText: d.choiceText||'', requirementType: d.requirementType||'', requirementValue: d.requirementValue||1, rewardEnergy: d.rewardEnergy||0, displayOrder: d.displayOrder||0 };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/stories'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.title?.trim()) { toastStore.error('标题不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createStory(formData); toastStore.success('章节已创建'); goto('/admin/stories'); }
      else { await adminApi.updateStory(itemId, formData); toastStore.success('章节已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteStory(itemId); toastStore.success('章节已删除'); goto('/admin/stories'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/stories')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回章节列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建章节' : '编辑章节 #' + itemId}</h2>
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
        <div><label class="block text-sm text-gray-500 mb-1">章节号 *</label><input type="number" bind:value={formData.chapterNumber} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">标题 *</label><input type="text" bind:value={formData.title} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">剧情内容</label><textarea bind:value={formData.narrative} rows="4" class="w-full px-3 py-2 border rounded-lg text-sm"></textarea></div>
      <div class="grid grid-cols-2 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">NPC名称</label><input type="text" bind:value={formData.npcName} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">NPC对话</label><input type="text" bind:value={formData.npcDialogue} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">选择文本</label><input type="text" bind:value={formData.choiceText} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">解锁条件类型</label><input type="text" bind:value={formData.requirementType} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">条件值</label><input type="number" bind:value={formData.requirementValue} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">奖励精力⚡</label><input type="number" bind:value={formData.rewardEnergy} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">排序</label><input type="number" bind:value={formData.displayOrder} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该章节吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
