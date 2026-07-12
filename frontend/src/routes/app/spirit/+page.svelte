<script lang="ts">
  import { getSpirits } from '$lib/api/spirit';
  import { goto } from '$app/navigation';
  import type { SpiritDTO } from '$lib/types/api';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import DormancyOverlay from '$lib/components/spirit/DormancyOverlay.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import SkeletonTemplates from '$lib/components/common/SkeletonTemplates.svelte';
  import ErrorState from '$lib/components/common/ErrorState.svelte';

  let spirits = $state<SpiritDTO[]>([]);
  let loading = $state(true);
  let loadError = $state('');

  $effect(() => {
    getSpirits().then(list => {
      spirits = list;
      loading = false;
    }).catch(() => {
      loading = false;
      loadError = '无法加载精灵数据，请检查网络或重新登录';
    });
  });

  function startStudy() {
    spiritStore.dismissGreeting();
    goto('/app/study');
  }
</script>

<svelte:head>
  <title>我的精灵 - Pet Grow Up</title>
</svelte:head>

<div class="animate-slide-up">
  <h1 class="text-2xl font-bold text-gray-800 mb-6">我的精灵</h1>

  {#if loading}
    <SkeletonTemplates name="spirits" />
  {:else if loadError}
    <ErrorState type="auth" message={loadError} />
  {:else if spirits.length === 0}
    <ErrorState type="empty" message="还没有精灵，快去选择你的第一个伙伴！" actionLabel="选择精灵" onAction={() => goto('/app/spirit/choose')} />
  {:else}
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {#each spirits as spirit}
        <button
          onclick={() => goto(`/app/spirit/${spirit.id}`)}
          class="bg-white rounded-2xl shadow-sm p-5 border border-gray-100 hover:shadow-md transition text-left"
        >
          <div class="flex items-center justify-between mb-3">
            <SpiritAvatar species={spirit.species} evolutionStage={spirit.currentEvolutionStage} size="sm" />
            {#if spirit.isActive}
              <span class="text-xs bg-green-100 text-green-600 px-2 py-1 rounded-full">当前</span>
            {/if}
          </div>
          <h3 class="font-bold text-gray-800">{spirit.nickname}</h3>
          <p class="text-sm text-gray-500">{spirit.species.name}</p>
          <div class="mt-3 space-y-2">
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-500">亲密度</span>
              <span class="font-medium text-gray-700">{spirit.affection}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-500">快乐度</span>
              <span class="font-medium text-gray-700">{spirit.happiness}%</span>
            </div>
          </div>
        </button>
      {/each}
    </div>
  {/if}

  <!-- Sprint C: Dormancy overlay -->
  {#if spiritStore.dormancyLevel >= 2 && spiritStore.activeSpirit}
    <DormancyOverlay
      species={spiritStore.activeSpirit.species}
      nickname={spiritStore.activeSpirit.nickname}
      personality={spiritStore.personalityType as any}
      onWakeUp={startStudy}
    />
  {/if}
</div>