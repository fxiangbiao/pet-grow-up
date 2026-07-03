<script lang="ts">
  // Overlay shown when the spirit is in deep dormancy (3+ days).
  // Gentle nudge to encourage the child to study and "wake up" their spirit.

  import SpiritAvatar from './SpiritAvatar.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    species,
    nickname = '星灵',
    personality = 'cheerful',
    onWakeUp = () => {}
  }: {
    species: SpiritSpecies | null;
    nickname?: string;
    personality?: 'cheerful' | 'gentle' | 'tsundere' | 'brave';
    onWakeUp?: () => void;
  } = $props();

  const wakeUpMessages: Record<string, string> = {
    cheerful: '快来做题让我恢复元气吧！',
    gentle: '一起学习的话，我就能醒过来了...',
    tsundere: '哼！你再不学我就要睡到明年了！',
    brave: '紧急情况！需要学习能量支援！'
  };
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm animate-fade-in"
  onclick={(e) => { if (e.target === e.currentTarget) onWakeUp(); }}
  onkeydown={(e) => { if (e.key === 'Escape') onWakeUp(); }}
  role="dialog"
  tabindex="-1"
  aria-label="星灵在等你唤醒"
>
  <div class="bg-white rounded-3xl shadow-2xl p-8 max-w-sm mx-4 text-center animate-scale-in">
    <!-- Sleeping spirit -->
    <div class="mb-4 flex justify-center">
      {#if species}
        <SpiritAvatar {species} evolutionStage={1} size="lg" mood="sleeping" {personality} dormancyLevel={2} showSpeechBubble={false} />
      {:else}
        <div class="text-6xl">💤</div>
      {/if}
    </div>

    <h2 class="text-xl font-bold text-gray-800 mb-2">
      {nickname} 睡着了...
    </h2>
    <p class="text-gray-500 text-sm mb-1">
      你已经 3 天没有来学习啦
    </p>
    <p class="text-indigo-500 text-sm font-medium mb-6 italic">
      「{wakeUpMessages[personality] || wakeUpMessages.cheerful}」
    </p>

    <button
      onclick={onWakeUp}
      class="w-full py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl font-bold
        hover:from-indigo-600 hover:to-purple-600 transition shadow-lg active:scale-[0.98]"
    >
      ✨ 开始学习，唤醒{ nickname }！
    </button>

    <p class="text-gray-400 text-xs mt-3">
      完成任意一次学习挑战即可唤醒
    </p>
  </div>
</div>

<style>
  @keyframes fadeIn {
    0% { opacity: 0; }
    100% { opacity: 1; }
  }
  @keyframes scaleIn {
    0% { transform: scale(0.85); opacity: 0; }
    100% { transform: scale(1); opacity: 1; }
  }
  :global(.animate-fade-in) { animation: fadeIn 0.4s ease-out; }
  :global(.animate-scale-in) { animation: scaleIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1); }
</style>
