<script lang="ts">
  import { goto } from '$app/navigation';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    subject = 'chinese',
    subjectName = '',
    subjectEmoji = '🌍',
    species = null as SpiritSpecies | null,
    evolutionStage = 1,
    mood = 'idle' as 'idle' | 'happy' | 'excited' | 'hurt',
    loading = false,
    error = '',
    onStart = () => {}
  }: {
    subject?: string;
    subjectName?: string;
    subjectEmoji?: string;
    species?: SpiritSpecies | null;
    evolutionStage?: number;
    mood?: 'idle' | 'happy' | 'excited' | 'hurt';
    loading?: boolean;
    error?: string;
    onStart?: () => void;
  } = $props();

  const infoItems = [
    { icon: '🗡', text: '5 场遭遇战' },
    { icon: '👑', text: '最终 Boss 战' },
    { icon: '💰', text: '连对 2 题触发宝箱' },
    { icon: '❤️', text: 'HP 5 | 答错扣 1 | Boss 扣 2' },
    { icon: '🔥', text: '连击倍率 ×1 → ×1.5 → ×2' },
  ];
</script>

<div class="text-center">
  <button onclick={() => goto(`/app/study/${subject}`)} class="text-gray-500 hover:text-gray-700 mb-6 flex items-center gap-1">
    ← 返回地图
  </button>

  <div class="bg-white rounded-2xl shadow-sm p-8 border border-gray-100">
    <div class="text-6xl mb-4">{subjectEmoji}</div>
    {#if species}
      <div class="flex justify-center mb-4">
        <SpiritAvatar {species} {evolutionStage} size="md" {mood} />
      </div>
    {/if}
    <h1 class="text-2xl font-bold text-gray-800 mb-2">{subjectName}</h1>
    <p class="text-gray-500 mb-4">精灵伙伴与你同行！</p>

    {#if error}
      <div class="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm">{error}</div>
    {/if}

    <div class="bg-gray-50 rounded-xl p-4 text-left text-sm text-gray-600 space-y-1.5 mb-6">
      {#each infoItems as item}
        <p>{item.icon} {item.text}</p>
      {/each}
    </div>

    <button onclick={onStart} disabled={loading}
            class="w-full py-3 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl font-semibold text-lg hover:from-indigo-600 hover:to-purple-700 disabled:opacity-50 transition shadow-md">
      {loading ? '准备中...' : '开始冒险！'}
    </button>
  </div>
</div>
