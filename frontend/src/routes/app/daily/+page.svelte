<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { getTodayChallenges, claimReward } from '$lib/api/challenge';
  import type { DailyChallenge } from '$lib/types/api';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import SkeletonTemplates from '$lib/components/common/SkeletonTemplates.svelte';
  import ErrorState from '$lib/components/common/ErrorState.svelte';

  let challenges = $state<DailyChallenge[]>([]);
  let loading = $state(true);
  let loadError = $state('');
  let claiming = $state<number | null>(null);

  async function load() {
    loading = true;
    loadError = '';
    try {
      challenges = await getTodayChallenges();
    } catch (e) {
      loadError = '加载挑战失败';
    }
    loading = false;
  }

  async function handleClaim(userChallengeId: number) {
    claiming = userChallengeId;
    try {
      await claimReward(userChallengeId);
      toastStore.success('领取成功！');
      authStore.refreshProfile();
      challenges = challenges.map(c =>
        c.id === userChallengeId ? { ...c, rewardClaimed: true } : c
      );
    } catch (e: any) {
      toastStore.error(e.message || '领取失败');
    } finally {
      claiming = null;
    }
  }

  const today = $derived(new Date().toLocaleDateString('zh-CN', {
    year: 'numeric', month: 'long', day: 'numeric', weekday: 'long'
  }));

  function goToChallenge(type: string) {
    switch (type) {
      case 'STUDY_SESSION':
      case 'ACCURACY':
      case 'PERFECT_SESSION':
      case 'ENERGY_EARN':
        goto('/app/study');
        break;
    }
  }

  onMount(load);
</script>

<svelte:head>
  <title>每日挑战 - Pet Grow Up</title>
</svelte:head>

<div class="max-w-xl mx-auto space-y-6 animate-slide-up">
  <div class="bg-white rounded-2xl shadow-sm p-6">
    <h1 class="text-2xl font-bold text-gray-800">每日挑战</h1>
    <p class="text-gray-500 mt-1">{today}</p>
    <p class="text-sm text-gray-400 mt-1">完成挑战获取额外能量奖励！</p>
  </div>

  {#if loading}
    <SkeletonTemplates name="daily" />
  {:else if loadError}
    <ErrorState type="server" message={loadError} onRetry={load} />
  {:else}
    <div class="space-y-3">
      {#each challenges as c (c.id)}
        <div
          role="button"
          tabindex="0"
          onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') goToChallenge(c.challengeType); }}
          onclick={() => goToChallenge(c.challengeType)}
          class="bg-white rounded-2xl shadow-sm p-5 border transition cursor-pointer hover:shadow-md
            {c.completed && !c.rewardClaimed ? 'border-amber-300 bg-amber-50/50' : 'border-gray-100'}"
        >
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-3">
              <span class="text-2xl">{c.iconUrl || '📋'}</span>
              <div>
                <h3 class="font-medium text-gray-800 text-sm">{c.description}</h3>
                <p class="text-xs text-amber-500 font-medium">⚡ {c.rewardEnergy} 能量</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              {#if c.rewardClaimed}
                <span class="text-xs bg-green-100 text-green-600 px-2.5 py-1 rounded-full font-medium">已领取</span>
              {:else if c.completed}
                <button
                  onclick={(e) => { e.stopPropagation(); handleClaim(c.id); }}
                  disabled={claiming === c.id}
                  class="px-4 py-1.5 text-xs bg-gradient-to-r from-amber-400 to-orange-400 text-white rounded-lg font-semibold hover:from-amber-500 hover:to-orange-500 transition disabled:opacity-50 animate-pulse"
                >
                  {claiming === c.id ? '领取中...' : '领取'}
                </button>
              {:else}
                <span class="text-xs text-gray-400">进行中</span>
              {/if}
            </div>
          </div>

          <!-- Progress bar -->
          <div class="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
            <div
              class="h-2 rounded-full transition-all duration-700 ease-out
                {c.completed ? 'bg-green-400' : 'bg-indigo-400'}"
              style="width: {Math.min((c.progress / c.targetValue) * 100, 100)}%"
            ></div>
          </div>
          <div class="flex justify-between mt-1">
            <span class="text-xs text-gray-400">
              {c.completed ? '已完成' : '进度: ' + c.progress + '/' + c.targetValue}
            </span>
            <span class="text-xs text-gray-400">
              {c.completed ? '100%' : Math.round((c.progress / c.targetValue) * 100) + '%'}
            </span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>