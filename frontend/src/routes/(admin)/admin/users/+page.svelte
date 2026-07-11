<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { adminApi, type UserFilter, type UserPage } from '$lib/api/admin';
  import { authStore } from '$lib/stores/auth.svelte';
  import { USER_ROLE_LABELS } from '$lib/components/admin/constants';
  import Pagination from '$lib/components/admin/Pagination.svelte';

  let filter = $state<UserFilter>({ page: 1, size: 20 });
  let pageData = $state<UserPage | null>(null);
  let loading = $state(false);
  let errorMsg = $state<string | null>(null);

  onMount(() => { loadUsers(); });

  async function loadUsers() {
    loading = true;
    errorMsg = null;
    try {
      pageData = await adminApi.listUsers(filter);
    } catch (e: any) {
      errorMsg = e.message || '加载失败';
      pageData = null;
    } finally {
      loading = false;
    }
  }

  function applyFilter(updates: Partial<UserFilter>) {
    filter = { ...filter, ...updates, page: 1 };
    loadUsers();
  }

  function goPage(p: number) {
    filter = { ...filter, page: p };
    loadUsers();
  }

  let totalPages = $derived(pageData ? Math.ceil(pageData.total / pageData.size) : 0);
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">👥 用户管理</h2>
  </div>

  <!-- Filters -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4">
    <div class="flex gap-3">
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => applyFilter({ role: (e.target as HTMLSelectElement).value || undefined })}>
        <option value="">全部角色</option>
        <option value="STUDENT">学生</option>
        <option value="ADMIN">管理员</option>
      </select>
      <input type="text" placeholder="搜索用户名/昵称/邮箱..." class="px-3 py-1.5 border rounded-lg text-sm flex-1"
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
            <th class="text-left px-4 py-2 font-medium text-gray-500">用户名</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">昵称</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">邮箱</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">角色</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">能量</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">连续学习</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">注册时间</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">操作</th>
          </tr>
        </thead>
        <tbody class="divide-y">
          {#each pageData.items as u}
            <tr class="hover:bg-gray-50">
              <td class="px-4 py-2 text-gray-400">{u.id}</td>
              <td class="px-4 py-2 font-medium">{u.username}</td>
              <td class="px-4 py-2">{u.nickname || '-'}</td>
              <td class="px-4 py-2 text-xs text-gray-500 max-w-[200px] truncate">{u.email}</td>
              <td class="px-4 py-2">
                <span class="text-xs px-2 py-0.5 rounded-full {u.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'}">
                  {USER_ROLE_LABELS[u.role] || u.role}
                </span>
              </td>
              <td class="px-4 py-2 text-center text-xs">⚡{u.currentEnergy}</td>
              <td class="px-4 py-2 text-xs">{u.consecutiveStudyDays} 天</td>
              <td class="px-4 py-2 text-xs text-gray-500">{u.createdAt?.slice(0, 10) || '-'}</td>
              <td class="px-4 py-2 text-center">
                <button onclick={() => goto(`/admin/users/${u.id}`)}
                        class="text-indigo-600 hover:text-indigo-800 text-xs">管理</button>
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
      <div class="text-center text-gray-400 py-12">暂无用户</div>
    {/if}
  </div>
</div>
