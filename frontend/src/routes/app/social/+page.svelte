<script lang="ts">
  import FriendList from '$lib/components/social/FriendList.svelte';
  import FriendRequests from '$lib/components/social/FriendRequests.svelte';
  import SearchUsers from '$lib/components/social/SearchUsers.svelte';
  import Leaderboard from '$lib/components/social/Leaderboard.svelte';

  const tabs = [
    { key: 'friends', label: '好友', icon: '👥' },
    { key: 'leaderboard', label: '排行榜', icon: '🏆' }
  ];

  let activeTab = $state('friends');
</script>

<svelte:head>
  <title>社交 - Pet Grow Up</title>
</svelte:head>

<div class="space-y-6 animate-slide-up">
  <div class="bg-white rounded-2xl shadow-sm p-6">
    <h1 class="text-2xl font-bold text-gray-800">社交中心</h1>
    <p class="text-gray-500 mt-1">与朋友一起学习，共同进步！</p>
  </div>

  <div class="flex gap-2">
    {#each tabs as tab}
      <button
        onclick={() => activeTab = tab.key}
        class="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition
          {activeTab === tab.key
            ? 'bg-indigo-100 text-indigo-700 shadow-sm'
            : 'bg-white text-gray-500 hover:bg-gray-50'}"
      >
        <span>{tab.icon}</span>
        {tab.label}
      </button>
    {/each}
  </div>

  {#if activeTab === 'friends'}
    <SearchUsers />
    <FriendRequests />
    <FriendList />
  {:else if activeTab === 'leaderboard'}
    <Leaderboard />
  {/if}
</div>
