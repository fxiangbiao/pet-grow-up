<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi, type UserRow } from '$lib/api/admin';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import { USER_ROLE_LABELS } from '$lib/components/admin/constants';

  let userId = $derived(Number($page.params.id));
  let user = $state<UserRow | null>(null);
  let loading = $state(true);
  let savingRole = $state(false);
  let selectedRole = $state('');
  let showResetModal = $state(false);
  let newPassword = $state('');

  // Can't manage yourself
  let isSelf = $derived(authStore.user?.id === userId);

  onMount(() => { loadUser(); });

  async function loadUser() {
    loading = true;
    try {
      user = await adminApi.getUser(userId);
      selectedRole = user?.role || '';
    } catch (e: any) {
      toastStore.error(e.message || '加载失败');
      goto('/admin/users');
    } finally {
      loading = false;
    }
  }

  async function handleRoleChange() {
    if (!user || selectedRole === user.role) return;
    savingRole = true;
    try {
      await adminApi.updateUserRole(userId, selectedRole);
      toastStore.success('角色已更新');
      await loadUser();
    } catch (e: any) {
      toastStore.error(e.message || '更新失败');
      selectedRole = user?.role || '';
    } finally {
      savingRole = false;
    }
  }

  async function handleResetPassword() {
    try {
      await adminApi.resetUserPassword(userId, newPassword || undefined);
      toastStore.success(newPassword ? '密码已重置' : '密码已重置为默认密码 pet123456');
      showResetModal = false;
      newPassword = '';
    } catch (e: any) {
      toastStore.error(e.message || '重置失败');
    }
  }
</script>

<div>
  <!-- Header -->
  <div class="flex items-center gap-4 mb-6">
    <button onclick={() => goto('/admin/users')}
            class="text-gray-500 hover:text-gray-700 text-sm">← 返回用户列表</button>
  </div>

  {#if loading}
    <div class="text-center text-gray-400 py-12">加载中...</div>
  {:else if user}
    <!-- User info card -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <div class="flex items-center gap-4 mb-4">
        <div class="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center text-2xl">
          {user.nickname?.[0] || user.username[0]}
        </div>
        <div>
          <h2 class="text-xl font-bold text-gray-800">{user.nickname || user.username}</h2>
          <p class="text-sm text-gray-500">@{user.username} · ID: {user.id}</p>
        </div>
        <span class="ml-auto text-xs px-3 py-1 rounded-full {user.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'}">
          {USER_ROLE_LABELS[user.role] || user.role}
        </span>
      </div>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div><span class="text-gray-400">邮箱</span><br>{user.email}</div>
        <div><span class="text-gray-400">当前能量</span><br>⚡ {user.currentEnergy}</div>
        <div><span class="text-gray-400">累计能量</span><br>⚡ {user.totalEnergy}</div>
        <div><span class="text-gray-400">连续学习</span><br>{user.consecutiveStudyDays} 天</div>
        <div><span class="text-gray-400">最后学习</span><br>{user.lastStudyDate || '-'}</div>
        <div><span class="text-gray-400">最后登录</span><br>{user.lastLoginDate || '-'}</div>
        <div><span class="text-gray-400">注册时间</span><br>{user.createdAt?.slice(0, 10) || '-'}</div>
      </div>
    </div>

    <!-- Role management -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <h3 class="text-lg font-semibold text-gray-800 mb-4">角色管理</h3>
      {#if isSelf}
        <div class="text-sm text-amber-600 bg-amber-50 rounded-lg p-3">⚠️ 不能修改自己的角色</div>
      {:else}
        <div class="flex items-center gap-4">
          <select bind:value={selectedRole} class="px-3 py-2 border rounded-lg text-sm">
            <option value="STUDENT">学生</option>
            <option value="ADMIN">管理员</option>
          </select>
          <button onclick={handleRoleChange} disabled={savingRole || selectedRole === user.role}
                  class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition disabled:opacity-40 disabled:cursor-not-allowed">
            {savingRole ? '保存中...' : '保存'}
          </button>
        </div>
      {/if}
    </div>

    <!-- Password reset -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h3 class="text-lg font-semibold text-gray-800 mb-4">重置密码</h3>
      {#if isSelf}
        <div class="text-sm text-amber-600 bg-amber-50 rounded-lg p-3">⚠️ 不能重置自己的密码</div>
      {:else}
        <button onclick={() => showResetModal = true}
                class="px-4 py-2 bg-red-50 text-red-600 text-sm rounded-lg hover:bg-red-100 transition border border-red-200">
          🔑 重置密码
        </button>
        <p class="text-xs text-gray-400 mt-2">留空则重置为默认密码 pet123456</p>
      {/if}
    </div>
  {/if}
</div>


{#if showResetModal}
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
       onclick={() => { showResetModal = false; newPassword = ''; }} role="presentation">
    <div class="bg-white rounded-2xl shadow-xl p-6 max-w-sm mx-4" onclick={(e) => e.stopPropagation()} role="dialog">
      <h3 class="text-lg font-bold text-gray-800 mb-4">重置密码</h3>
      <input type="text" placeholder="新密码（留空用默认 pet123456）" bind:value={newPassword}
             class="w-full px-3 py-2 border rounded-lg text-sm mb-4" />
      <div class="flex gap-3 justify-end">
        <button onclick={() => { showResetModal = false; newPassword = ''; }}
                class="px-4 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200 transition">取消</button>
        <button onclick={handleResetPassword}
                class="px-4 py-2 text-sm text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 transition">确认重置</button>
      </div>
    </div>
  </div>
{/if}
