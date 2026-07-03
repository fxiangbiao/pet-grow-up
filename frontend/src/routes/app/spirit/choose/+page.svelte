<script lang="ts">
  import { getSpecies, chooseStarter } from '$lib/api/spirit';
  import { authStore } from '$lib/stores/auth.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { goto } from '$app/navigation';
  import type { SpiritSpecies } from '$lib/types/api';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import PersonalityPicker from '$lib/components/spirit/PersonalityPicker.svelte';

  let speciesList = $state<SpiritSpecies[]>([]);
  let step = $state<1 | 2 | 3>(1);
  let selectedSpecies = $state<number | null>(null);
  let selectedPersonality = $state('');
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

  function goNext() {
    if (step < 3) step = (step + 1) as 1 | 2 | 3;
  }

  function goBack() {
    if (step > 1) { step = (step - 1) as 1 | 2 | 3; error = ''; }
  }

  const canNext = $derived(
    (step === 1 && selectedSpecies !== null) ||
    (step === 2 && selectedPersonality !== '') ||
    (step === 3 && nickname.trim().length > 0)
  );

  async function handleChoose() {
    if (!selectedSpecies || !selectedPersonality || !nickname.trim()) return;
    error = '';
    loading = true;
    try {
      const spirit = await chooseStarter(selectedSpecies, selectedPersonality, nickname.trim());
      await authStore.refreshProfile();
      await spiritStore.refresh(0);
      goto('/app');
    } catch (e: any) {
      error = e.message || '选择失败';
    } finally {
      loading = false;
    }
  }

  const currentSpecies = $derived(speciesList.find(s => s.id === selectedSpecies) ?? null);
</script>

<svelte:head>
  <title>选择精灵 - Pet Grow Up</title>
</svelte:head>

<div class="max-w-4xl mx-auto animate-slide-up px-4 pb-16">
  <h1 class="text-3xl font-bold text-center text-gray-800 mb-2">✨ 选择你的学习精灵</h1>
  <p class="text-center text-gray-500 mb-2">每个精灵都来自一个奇幻世界，选择你的第一个伙伴吧！</p>

  <!-- Step indicator -->
  <div class="flex items-center justify-center gap-2 mb-8">
    {#each [1, 2, 3] as i}
      <button
        onclick={() => { if (i < step || (i === 1 && step > 1)) step = i as 1|2|3; }}
        class={[
          'w-8 h-8 rounded-full text-sm font-bold transition-all flex items-center justify-center',
          step === i
            ? 'bg-indigo-500 text-white shadow-md'
            : step > i
              ? 'bg-emerald-400 text-white cursor-pointer'
              : 'bg-gray-200 text-gray-400'
        ].join(' ')}
      >
        {#if step > i}✓{:else}{i}{/if}
      </button>
      {#if i < 3}
        <div class={['w-12 h-0.5 transition-colors', step > i ? 'bg-emerald-400' : 'bg-gray-200'].join(' ')}></div>
      {/if}
    {/each}
  </div>
  <p class="text-center text-sm text-gray-400 mb-8">
    {step === 1 ? '第一步：选择学科和精灵' : step === 2 ? '第二步：选择星灵性格' : '第三步：给你的星灵起个名字'}
  </p>

  {#if error}
    <div class="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm max-w-md mx-auto">
      {error}
    </div>
  {/if}

  <!-- Step 1: Choose species -->
  {#if step === 1}
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      {#each speciesList as species}
        <button
          onclick={() => { selectedSpecies = species.id; }}
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
  {/if}

  <!-- Step 2: Choose personality -->
  {#if step === 2}
    <div class="max-w-lg mx-auto">
      <PersonalityPicker bind:selected={selectedPersonality} />
    </div>
  {/if}

  <!-- Step 3: Name & confirm -->
  {#if step === 3}
    <div class="max-w-md mx-auto">
      <!-- Preview of selections -->
      {#if currentSpecies}
        <div class="flex items-center justify-center gap-4 mb-6 p-4 bg-white rounded-2xl border border-gray-200 shadow-sm">
          <div class="flex-shrink-0">
            <SpiritAvatar species={currentSpecies} evolutionStage={1} size="sm" personality={selectedPersonality as any} />
          </div>
          <div>
            <div class="font-bold text-gray-800">{currentSpecies.name}</div>
            <div class="text-sm text-gray-400">{subjectLabels[currentSpecies.subject]}</div>
            <div class="text-xs text-indigo-500 mt-0.5">
              {selectedPersonality === 'cheerful' ? '🎉 元气活泼' :
               selectedPersonality === 'gentle' ? '🌸 温柔治愈' :
               selectedPersonality === 'tsundere' ? '😤 傲娇呆萌' :
               selectedPersonality === 'brave' ? '⚔️ 勇敢冒险' : ''}
            </div>
          </div>
        </div>
      {/if}

      <label for="nickname" class="block text-sm font-medium text-gray-700 mb-2">给你的星灵起个名字</label>
      <input
        id="nickname"
        type="text"
        bind:value={nickname}
        maxlength={20}
        placeholder="输入昵称..."
        class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none text-lg text-center"
        onkeydown={(e) => { if (e.key === 'Enter' && canNext) handleChoose(); }}
      />
      <p class="text-xs text-gray-400 text-center mt-1">{20 - nickname.length} 个字符可用</p>
    </div>
  {/if}

  <!-- Navigation buttons -->
  <div class="flex justify-center gap-3 mt-8">
    {#if step > 1}
      <button onclick={goBack}
        class="px-6 py-2.5 border-2 border-gray-300 text-gray-600 rounded-xl font-medium hover:bg-gray-50 transition">
        ← 上一步
      </button>
    {/if}

    {#if step < 3}
      <button onclick={goNext} disabled={!canNext}
        class="px-8 py-2.5 bg-indigo-500 text-white rounded-xl font-semibold hover:bg-indigo-600 disabled:opacity-40 disabled:cursor-not-allowed transition">
        下一步 →
      </button>
    {:else}
      <button
        onclick={handleChoose}
        disabled={loading || !canNext}
        class="px-8 py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl font-bold hover:from-indigo-600 hover:to-purple-600 disabled:opacity-40 disabled:cursor-not-allowed transition shadow-lg"
      >
        {loading ? '✨ 召唤中...' : '🎉 召唤我的星灵！'}
      </button>
    {/if}
  </div>
</div>
