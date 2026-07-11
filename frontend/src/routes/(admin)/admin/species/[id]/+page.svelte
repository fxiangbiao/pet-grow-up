<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { SPECIES_SUBJECT_LABELS } from '$lib/components/admin/constants';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let itemId = $derived(Number($page.params.id));
  let isNew = $derived($page.params.id === 'new');
  let loading = $state(true);
  let saving = $state(false);
  let showDeleteModal = $state(false);
  let formData = $state({ speciesKey: '', name: '', subject: 'math', description: '', evolutionStage: 1, evolvesFromId: null, evolutionEnergyCost: 0, baseAffection: 0, spriteUrl: '', animationData: '' });

  onMount(() => { if (!isNew) load(); else loading = false; });
  async function load() {
    loading = true;
    try { const d = await adminApi.getSpecies(itemId);
      formData = { speciesKey: d.speciesKey, name: d.name, subject: d.subject, description: d.description||'', evolutionStage: d.evolutionStage||1, evolvesFromId: d.evolvesFromId||null, evolutionEnergyCost: d.evolutionEnergyCost||0, baseAffection: d.baseAffection||0, spriteUrl: d.spriteUrl||'', animationData: d.animationData||'' };
    } catch (e: any) { toastStore.error(e.message || '加载失败'); goto('/admin/species'); } finally { loading = false; }
  }
  async function handleSave() {
    if (!formData.speciesKey?.trim()) { toastStore.error('物种标识不能为空'); return; }
    if (!formData.name?.trim()) { toastStore.error('物种名称不能为空'); return; }
    saving = true;
    try { if (isNew) { await adminApi.createSpecies(formData); toastStore.success('物种已创建'); goto('/admin/species'); }
      else { await adminApi.updateSpecies(itemId, formData); toastStore.success('物种已保存'); }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); } finally { saving = false; }
  }
  async function handleDelete() { try { await adminApi.deleteSpecies(itemId); toastStore.success('物种已删除'); goto('/admin/species'); } catch (e: any) { toastStore.error(e.message); } finally { showDeleteModal = false; } }
</script>

<div>
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <button onclick={() => goto('/admin/species')} class="text-gray-500 hover:text-gray-700 text-sm">← 返回物种列表</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建物种' : '编辑物种 #' + itemId}</h2>
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
        <div><label class="block text-sm text-gray-500 mb-1">物种标识 *</label><input type="text" bind:value={formData.speciesKey} disabled={!isNew} class="w-full px-3 py-2 border rounded-lg text-sm disabled:bg-gray-50" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">名称 *</label><input type="text" bind:value={formData.name} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div class="grid grid-cols-3 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">学科</label><select bind:value={formData.subject} class="w-full px-3 py-2 border rounded-lg text-sm">{#each Object.entries(SPECIES_SUBJECT_LABELS) as [k,v]}<option value={k}>{v}</option>{/each}</select></div>
        <div><label class="block text-sm text-gray-500 mb-1">进化阶段</label><input type="number" min="1" max="3" bind:value={formData.evolutionStage} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">基础亲密度</label><input type="number" bind:value={formData.baseAffection} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div class="grid grid-cols-2 gap-4">
        <div><label class="block text-sm text-gray-500 mb-1">进化源头 ID</label><input type="number" bind:value={formData.evolvesFromId} class="w-full px-3 py-2 border rounded-lg text-sm" placeholder="无" /></div>
        <div><label class="block text-sm text-gray-500 mb-1">进化成本⚡</label><input type="number" bind:value={formData.evolutionEnergyCost} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      </div>
      <div><label class="block text-sm text-gray-500 mb-1">描述</label><textarea bind:value={formData.description} rows="2" class="w-full px-3 py-2 border rounded-lg text-sm"></textarea></div>
      <div><label class="block text-sm text-gray-500 mb-1">立绘 URL</label><input type="text" bind:value={formData.spriteUrl} class="w-full px-3 py-2 border rounded-lg text-sm" /></div>
      <div><label class="block text-sm text-gray-500 mb-1">动画数据 (JSON)</label><textarea bind:value={formData.animationData} rows="3" class="w-full px-3 py-2 border rounded-lg text-sm font-mono"></textarea></div>
    </div>
  {/if}
</div>
<ConfirmModal show={showDeleteModal} title="确认删除" confirmText="删除" message="确定要删除该物种吗？" onConfirm={handleDelete} onCancel={() => showDeleteModal = false} />
