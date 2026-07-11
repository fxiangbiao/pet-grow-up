<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { adminApi } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { SPECIES_SUBJECT_LABELS } from '$lib/components/admin/constants';
  import Pagination from '$lib/components/admin/Pagination.svelte';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let filter = $state<any>({ page: 1, size: 20, subject: undefined, keyword: undefined });
  let pageData = $state<any>({ items: [], total: 0, page: 1, size: 20 });
  let loading = $state(false);
  let confirmDelete = $state(null);

  onMount(() => { load(); });
  async function load() { loading = true; try { pageData = await adminApi.listSpecies(filter); } catch (e: any) { toastStore.error(e.message || '加载失败'); } finally { loading = false; } }
  function applyFilter(updates: any) { filter = { ...filter, ...updates, page: 1 }; load(); }
  function goPage(p: number) { filter = { ...filter, page: p }; load(); }
  async function handleDelete(id: number) { try { await adminApi.deleteSpecies(id); toastStore.success('物种已删除'); confirmDelete = null; load(); } catch (e: any) { toastStore.error(e.message || '删除失败'); } }
  let totalPages = $derived(Math.ceil(pageData.total / pageData.size));
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">🐾 精灵物种管理</h2>
    <button onclick={() => goto('/admin/species/new')} class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition">➕ 新建物种</button>
  </div>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4">
    <div class="flex gap-3">
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e) => applyFilter({ subject: (e.target as HTMLInputElement).value || undefined })}>
        <option value="">全部学科</option>
        {#each Object.entries(SPECIES_SUBJECT_LABELS) as [key, label]}<option value={key}>{label}</option>{/each}
      </select>
      <input type="text" placeholder="搜索名称/标识..." class="px-3 py-1.5 border rounded-lg text-sm flex-1"
             onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') applyFilter({ keyword: (e.target as HTMLInputElement).value || undefined }); }}/>
    </div>
  </div>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
    {#if loading}<div class="text-center text-gray-400 py-12">加载中...</div>
    {:else if pageData.items.length > 0}
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b"><tr>
          <th class="text-left px-4 py-2 font-medium text-gray-500 w-12">ID</th>
          <th class="text-left px-4 py-2 font-medium text-gray-500">名称</th>
          <th class="text-left px-4 py-2 font-medium text-gray-500">标识</th>
          <th class="text-left px-4 py-2 font-medium text-gray-500">学科</th>
          <th class="text-center px-4 py-2 font-medium text-gray-500">进化阶段</th>
          <th class="text-center px-4 py-2 font-medium text-gray-500">进化成本</th>
          <th class="text-center px-4 py-2 font-medium text-gray-500">基础亲密</th>
          <th class="text-center px-4 py-2 font-medium text-gray-500">操作</th>
        </tr></thead>
        <tbody class="divide-y">
          {#each pageData.items as item}
            <tr class="hover:bg-gray-50">
              <td class="px-4 py-2 text-gray-400">{item.id}</td>
              <td class="px-4 py-2 font-medium">{item.name}</td>
              <td class="px-4 py-2 text-xs text-gray-500 font-mono">{item.speciesKey}</td>
              <td class="px-4 py-2"><span class="text-xs bg-sky-100 text-sky-700 px-2 py-0.5 rounded-full">{SPECIES_SUBJECT_LABELS[item.subject] || item.subject}</span></td>
              <td class="px-4 py-2 text-center">Stage {item.evolutionStage}</td>
              <td class="px-4 py-2 text-center text-xs">⚡{item.evolutionEnergyCost}</td>
              <td class="px-4 py-2 text-center text-xs">{item.baseAffection}</td>
              <td class="px-4 py-2 text-center">
                <button onclick={() => goto('/admin/species/' + item.id)} class="text-indigo-600 hover:text-indigo-800 text-xs mr-2">编辑</button>
                <button onclick={() => confirmDelete = item.id} class="text-red-500 hover:text-red-700 text-xs">删除</button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
      <Pagination page={filter.page} totalPages={totalPages} total={pageData.total} {goPage} />
    {:else}<div class="text-center text-gray-400 py-12">暂无物种</div>{/if}
  </div>
</div>
<ConfirmModal show={confirmDelete !== null} title="确认删除" confirmText="删除" message="确定要删除该物种吗？"
              onConfirm={() => confirmDelete !== null && handleDelete(confirmDelete)} onCancel={() => confirmDelete = null} />
