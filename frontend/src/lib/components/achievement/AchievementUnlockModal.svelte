<script lang="ts">
  import { soundManager } from '$lib/audio/sound-manager';
  import type { AchievementUnlockEvent } from '$lib/types/api';

  let { event, onClose }: { event: AchievementUnlockEvent; onClose: () => void } = $props();

  let particles = $state<Array<{ id: number; x: number; delay: number; emoji: string }>>([]);

  $effect(() => {
    soundManager.playCelebrate();
  });

  const emojis = ['🌟', '✨', '🎉', '🎊', '⭐', '💫', '🏆'];

  const rarityColors: Record<string, string> = {
    COMMON: 'from-gray-400 to-gray-300',
    RARE: 'from-blue-400 to-indigo-400',
    EPIC: 'from-purple-400 to-violet-400',
    LEGENDARY: 'from-amber-400 to-yellow-300'
  };

  const rarityLabels: Record<string, string> = {
    COMMON: '普通',
    RARE: '稀有',
    EPIC: '史诗',
    LEGENDARY: '传说'
  };

  const categoryIcons: Record<string, string> = {
    STUDY: '📚',
    SUBJECT: '📖',
    SPIRIT: '🐱',
    COLLECTION: '🏆',
    EVENT: '🎯',
    SOCIAL: '👥'
  };

  let rarity = $derived(event.achievement.rarity || 'COMMON');
  let gradient = $derived(rarityColors[rarity] || rarityColors.COMMON);

  $effect(() => {
    const items = Array.from({ length: 16 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      delay: Math.random() * 0.8,
      emoji: emojis[Math.floor(Math.random() * emojis.length)]
    }));
    particles = items;
  });
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-fade-in">
  <!-- Particles -->
  <div class="absolute inset-0 pointer-events-none overflow-hidden">
    {#each particles as p (p.id)}
      <div
        class="absolute text-2xl animate-float"
        style="left: {p.x}%; top: -10%; animation-delay: {p.delay}s;"
      >
        {p.emoji}
      </div>
    {/each}
  </div>

  <!-- Modal -->
  <div class="relative bg-white rounded-3xl shadow-2xl p-8 max-w-sm w-full mx-4 text-center animate-scale-in">
    <div class="text-6xl mb-4">{categoryIcons[event.achievement.category] || '🏅'}</div>

    <div class="inline-block px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r {gradient} text-white mb-3">
      {rarityLabels[rarity]}成就
    </div>

    <h2 class="text-2xl font-bold text-gray-800 mb-2">{event.achievement.name}</h2>
    <p class="text-sm text-gray-500 mb-6">{event.achievement.description}</p>

    {#if event.energyRewarded > 0}
      <div class="bg-amber-50 rounded-xl p-3 mb-6 flex items-center justify-center gap-2">
        <span class="text-xl">⚡</span>
        <span class="text-amber-700 font-semibold">获得 {event.energyRewarded} 学习能量！</span>
      </div>
    {/if}

    {#if event.titleGranted}
      <div class="bg-purple-50 rounded-xl p-3 mb-6">
        <span class="text-purple-700 font-semibold">解锁称号：{event.titleGranted}</span>
      </div>
    {/if}

    <button
      onclick={onClose}
      class="w-full py-3 px-6 bg-gradient-to-r {gradient} text-white font-semibold rounded-xl hover:opacity-90 transition active:scale-95"
    >
      太棒了！
    </button>
  </div>
</div>

<style>
  :global(.animate-fade-in) {
    animation: fadeIn 0.3s ease-out;
  }
  :global(.animate-scale-in) {
    animation: scaleIn 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes scaleIn {
    from { transform: scale(0.8); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
  }
</style>
