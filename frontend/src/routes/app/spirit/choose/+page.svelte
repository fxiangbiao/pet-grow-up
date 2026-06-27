<script lang="ts">
  import { getSpecies, chooseStarter } from '$lib/api/spirit';
  import { authStore } from '$lib/stores/auth.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { goto } from '$app/navigation';
  import type { SpiritSpecies } from '$lib/types/api';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';

  let speciesList = $state<SpiritSpecies[]>([]);
  let selectedSpecies = $state<number | null>(null);
  let nickname = $state('');
  let loading = $state(false);
  let error = $state('');
  let loaded = $state(false);

  const subjectLabels: Record<string, string> = {
    chinese: '诗词大陆',
    math: '智慧王国',
    english: '魔法学院'
  };

  const subjectColors: Record<string, string> = {
    chinese: 'border-amber-400 bg-amber-50',
    math: 'border-blue-400 bg-blue-50',
    english: 'border-purple-400 bg-purple-50'
  };

  $effect(() => {
    if (!loaded) {
      loaded = true;
      getSpecies().then(list => { speciesList = list; });
    }
  });

  async function handleChoose() {
    if (!selectedSpecies || !nickname.trim()) return;
    error = '';
    loading = true;
    try {
      const spirit = await chooseStarter(selectedSpecies, nickname.trim());
      await authStore.refreshProfile();
      await spiritStore.refresh(0);
      goto('/app');
    } catch (e: any) {
      error = e.message || '选择失败';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>选择精灵 - Pet Grow Up</title>
</svelte:head>

<div class="max-w-4xl mx-auto animate-slide-up">
  <h1 class="text-3xl font-bold text-center text-gray-800 mb-2">选择你的学习精灵</h1>
  <p class="text-center text-gray-500 mb-8">每个精灵都对应一个学科，选择你的第一个伙伴吧！</p>

  {#if error}
    <div class="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm max-w-md mx-auto">
      {error}
    </div>
  {/if}

  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    {#each speciesList as species}
      <button
        onclick={() => selectedSpecies = species.id}
        class={[
          'rounded-2xl p-6 border-2 transition-all cursor-pointer text-left',
          selectedSpecies === species.id
            ? (subjectColors[species.subject] || 'border-indigo-400 bg-indigo-50') + ' shadow-lg scale-105'
            : 'border-gray-200 bg-white hover:border-gray-300 hover:shadow-md'
        ].join(' ')}
      >
        <div class="mb-4 flex justify-center">
          <SpiritAvatar {species} evolutionStage={1} size="md" />
        </div>
        <h3 class="text-xl font-bold text-gray-800 text-center mb-1">{species.name}</h3>
        <p class="text-sm text-gray-500 text-center mb-3">{subjectLabels[species.subject] || species.subject}</p>
        <p class="text-sm text-gray-600">{species.description}</p>
      </button>
    {/each}
  </div>

  {#if selectedSpecies}
    <div class="max-w-md mx-auto bg-white rounded-2xl shadow-sm p-6 border border-gray-200">
      <label for="nickname" class="block text-sm font-medium text-gray-700 mb-2">给你的精灵起个名字</label>
      <input
        id="nickname"
        type="text"
        bind:value={nickname}
        maxlength={20}
        placeholder="输入昵称..."
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none mb-4"
      />
      <button
        onclick={handleChoose}
        disabled={loading || !nickname.trim()}
        class="w-full py-3 bg-indigo-500 text-white rounded-lg font-semibold hover:bg-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed transition"
      >
        {loading ? '选择中...' : '确定选择！'}
      </button>
    </div>
  {/if}
</div>
