<script lang="ts">
  import { searchUsers, sendFriendRequest } from '$lib/api/social';
  import { toastStore } from '$lib/stores/toast.svelte';
  import type { UserSearchResult } from '$lib/types/api';

  let query = $state('');
  let results = $state<UserSearchResult[]>([]);
  let searching = $state(false);
  let searchTimer: ReturnType<typeof setTimeout> | null = null;
  let showResults = $state(false);

  function onInput() {
    if (searchTimer) clearTimeout(searchTimer);
    if (query.trim().length < 1) {
      results = [];
      showResults = false;
      return;
    }
    searching = true;
    showResults = true;
    searchTimer = setTimeout(async () => {
      try {
        results = await searchUsers(query.trim());
      } catch {
        results = [];
      } finally {
        searching = false;
      }
    }, 300);
  }

  async function addFriend(userId: number) {
    try {
      await sendFriendRequest(userId);
      results = results.map(r =>
        r.userId === userId ? { ...r, hasPendingRequest: true } : r
      );
    } catch (e: any) {
      toastStore.error(e.message || '发送请求失败');
    }
  }
</script>

<div class="bg-white rounded-2xl shadow-sm p-4">
  <div class="relative">
    <input
      type="text"
      bind:value={query}
      oninput={onInput}
      placeholder="搜索用户名..."
      class="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 focus:border-indigo-300"
    />
    {#if searching}
      <span class="absolute right-3 top-3 text-gray-400 text-sm">搜索中...</span>
    {/if}
  </div>

  {#if showResults && results.length > 0}
    <div class="mt-3 space-y-2">
      {#each results as user}
        <div class="flex items-center justify-between py-2 px-3 hover:bg-gray-50 rounded-lg transition">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center text-sm text-indigo-600 font-medium">
              {user.nickname.charAt(0)}
            </div>
            <span class="text-sm font-medium text-gray-700">{user.nickname}</span>
          </div>
          <div>
            {#if user.isFriend}
              <span class="text-xs text-green-500">已是好友</span>
            {:else if user.hasPendingRequest}
              <span class="text-xs text-amber-500">已发送请求</span>
            {:else}
              <button
                onclick={() => addFriend(user.userId)}
                class="px-3 py-1 text-xs bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition"
              >
                添加好友
              </button>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  {:else if showResults && query.trim().length > 0 && !searching}
    <p class="mt-3 text-sm text-gray-400 text-center">未找到用户</p>
  {/if}
</div>
