<script lang="ts">
  import { onMount } from 'svelte';
  import { getIncomingRequests, getSentRequests, acceptFriendRequest, rejectFriendRequest } from '$lib/api/social';
  import { toastStore } from '$lib/stores/toast.svelte';
  import type { FriendRequestDTO } from '$lib/types/api';

  let incoming = $state<FriendRequestDTO[]>([]);
  let sent = $state<FriendRequestDTO[]>([]);

  async function load() {
    try {
      incoming = await getIncomingRequests();
      sent = await getSentRequests();
    } catch {}
  }

  async function accept(requestId: number) {
    try {
      await acceptFriendRequest(requestId);
      toastStore.success('已接受好友请求');
      await load();
    } catch (e: any) {
      toastStore.error(e.message || '操作失败');
    }
  }

  async function reject(requestId: number) {
    try {
      await rejectFriendRequest(requestId);
      toastStore.info('已拒绝好友请求');
      await load();
    } catch (e: any) {
      toastStore.error(e.message || '操作失败');
    }
  }

  onMount(load);
</script>

<div class="space-y-4">
  {#if incoming.length > 0}
    <div class="bg-white rounded-2xl shadow-sm p-4">
      <h2 class="text-sm font-semibold text-gray-700 mb-3">好友请求 ({incoming.length})</h2>
      <div class="space-y-3">
        {#each incoming as req (req.requestId)}
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center text-sm text-indigo-600 font-medium">
                {req.nickname.charAt(0)}
              </div>
              <span class="text-sm font-medium text-gray-700">{req.nickname}</span>
            </div>
            <div class="flex gap-2">
              <button
                onclick={() => accept(req.requestId)}
                class="px-3 py-1 text-xs bg-green-500 text-white rounded-lg hover:bg-green-600 transition"
              >
                接受
              </button>
              <button
                onclick={() => reject(req.requestId)}
                class="px-3 py-1 text-xs bg-gray-200 text-gray-600 rounded-lg hover:bg-gray-300 transition"
              >
                拒绝
              </button>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}

  {#if sent.length > 0}
    <div class="bg-white rounded-2xl shadow-sm p-4">
      <h2 class="text-sm font-semibold text-gray-700 mb-3">已发送的请求 ({sent.length})</h2>
      <div class="space-y-3">
        {#each sent as req (req.requestId)}
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-sm text-gray-600 font-medium">
                {req.nickname.charAt(0)}
              </div>
              <span class="text-sm font-medium text-gray-700">{req.nickname}</span>
            </div>
            <span class="text-xs text-amber-500">等待确认</span>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>
