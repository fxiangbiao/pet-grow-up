<script lang="ts">
  import { onMount } from 'svelte';
  import { getFriends, removeFriend } from '$lib/api/social';
  import { toastStore } from '$lib/stores/toast.svelte';
  import type { FriendDTO } from '$lib/types/api';
  import LoadingSpinner from '$lib/components/common/LoadingSpinner.svelte';
  import EmptyState from '$lib/components/common/EmptyState.svelte';
  import ConfirmModal from '$lib/components/common/ConfirmModal.svelte';

  let friends = $state<FriendDTO[]>([]);
  let loading = $state(true);
  let showRemoveConfirm = $state(false);
  let pendingRemoveId = $state<number | null>(null);

  async function load() {
    loading = true;
    try {
      friends = await getFriends();
    } catch {}
    loading = false;
  }

  function confirmRemove(friendId: number) {
    pendingRemoveId = friendId;
    showRemoveConfirm = true;
  }

  async function handleRemove() {
    if (pendingRemoveId === null) return;
    showRemoveConfirm = false;
    try {
      await removeFriend(pendingRemoveId);
      friends = friends.filter(f => f.friendId !== pendingRemoveId);
      toastStore.success('好友已删除');
    } catch (e: any) {
      toastStore.error(e.message || '操作失败');
    }
    pendingRemoveId = null;
  }

  function cancelRemove() {
    showRemoveConfirm = false;
    pendingRemoveId = null;
  }

  onMount(load);
</script>

<div class="bg-white rounded-2xl shadow-sm p-4">
  <h2 class="text-sm font-semibold text-gray-700 mb-3">好友列表 ({friends.length})</h2>

  {#if loading}
    <LoadingSpinner size="sm" text="加载好友列表..." />
  {:else if friends.length === 0}
    <EmptyState icon="👥" title="暂无好友" message="搜索其他用户并添加好友吧！" />
  {:else}
    <div class="space-y-3">
      {#each friends as friend (friend.friendId)}
        <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-b-0">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white font-medium">
              {friend.nickname.charAt(0)}
            </div>
            <div>
              <p class="text-sm font-medium text-gray-700">{friend.nickname}</p>
              <p class="text-xs text-gray-400">
                能量: {friend.totalEnergy} | 连续: {friend.consecutiveStudyDays}天
              </p>
            </div>
          </div>
          <button
            onclick={() => confirmRemove(friend.friendId)}
            class="px-2 py-1 text-xs text-red-500 hover:bg-red-50 rounded-lg transition"
          >
            删除
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>

<ConfirmModal
  show={showRemoveConfirm}
  title="删除好友"
  message="确定要删除这个好友吗？"
  confirmText="删除"
  cancelText="取消"
  onConfirm={handleRemove}
  onCancel={cancelRemove}
/>
