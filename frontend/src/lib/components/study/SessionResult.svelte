<script lang="ts">
  import { getSessionResult, type SessionResult as SessionResultDTO } from '$lib/api/study';
  import CelebrationOverlay from '$lib/components/feedback/CelebrationOverlay.svelte';
  import { authStore } from '$lib/stores/auth.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    subject, sessionId, onclose,
    maxCombo = 0, bossDefeated = false, treasuresFound = 0,
    startHp = 5, finalHp = 5
  }: {
    subject: string; sessionId: number; onclose: () => void;
    maxCombo?: number; bossDefeated?: boolean; treasuresFound?: number;
    startHp?: number; finalHp?: number;
  } = $props();

  let result = $state<SessionResultDTO | null>(null);
  let loading = $state(true);

  const cleared = $derived(finalHp > 0);

  $effect(() => {
    if (sessionId) {
      getSessionResult(sessionId, maxCombo, bossDefeated).then(r => {
        result = r;
        loading = false;
        authStore.refreshProfile();
        if (r.accuracy >= 0.8) {
          soundManager.playComplete();
        }
      });
    }
  });

  function getAccuracyColor(accuracy: number): string {
    if (accuracy >= 0.8) return 'text-green-500';
    if (accuracy >= 0.6) return 'text-yellow-500';
    return 'text-red-500';
  }

  function getSpiritMessage(reaction: string): string {
    const map: Record<string, string> = {
      EXCITED_BOUNCE: '精灵兴奋地跳来跳去！活泼的性格让它停不下来！',
      PROUD_ROAR: '精灵发出自豪的咆哮！勇敢的它为你骄傲！',
      EXCITED: '精灵非常兴奋！它为你感到骄傲！',
      PLAYFUL_CELEBRATE: '精灵调皮地翻了个跟头来庆祝！',
      HAPPY_DANCE: '精灵快乐地跳起了舞！',
      HAPPY: '精灵开心地在你身边转圈圈！',
      GENTLE_SMILE: '精灵温柔地微笑着，对你的表现很满意。',
      SHY_NOD: '精灵害羞地点了点头，小声说：真棒！',
      CONTENT: '精灵满意地点了点头。继续加油！',
      BRAVE_ENCOURAGE: '精灵挥舞着小拳头：加油，你能行！',
      GENTLE_COMFORT: '精灵轻轻拍了拍你的肩膀：没关系，下次加油。',
      ENCOURAGING: '精灵温柔地说：没关系，下次会更好！',
      SHY_LOOK_AWAY: '精灵害羞地低下头，但偷偷为你鼓掌。',
      PLAYFUL_GROAN: '精灵调皮地做了个鬼脸：这次不算！',
      TIRED: '精灵打了个哈欠：今天先休息吧～'
    };
    return map[reaction] || '精灵静静地看着你。';
  }

  const accuracyPercent = $derived(result ? Math.round(result.accuracy * 100) : 0);

  const subjectTheme = $derived.by(() => {
    const themes: Record<string, { emoji: string; name: string; accent: string; border: string }> = {
      chinese: { emoji: '📜', name: '诗词大陆', accent: 'text-amber-600', border: 'border-amber-200' },
      math: { emoji: '🔢', name: '智慧王国', accent: 'text-blue-600', border: 'border-blue-200' },
      english: { emoji: '🔤', name: '魔法学院', accent: 'text-purple-600', border: 'border-purple-200' }
    };
    return themes[subject] || themes.chinese;
  });
</script>

<div class="max-w-lg mx-auto animate-slide-up text-center">
  {#if loading}
    <div class="text-center text-gray-500 py-12">结算中...</div>
  {:else if result}
    {#if result.accuracy >= 0.8}
      <CelebrationOverlay />
    {/if}

    <div class="bg-white rounded-2xl shadow-sm p-8 border {subjectTheme.border} relative z-10">
      <div class="flex items-center justify-center gap-2 mb-2">
        <span class="text-lg">{subjectTheme.emoji}</span>
        <span class="text-sm {subjectTheme.accent} font-medium">{subjectTheme.name}</span>
      </div>
      <h1 class="text-2xl font-bold text-gray-800 mb-6">探险完成！</h1>

      <div class="text-8xl mb-4">
        {result.accuracy >= 0.8 ? '🌟' : result.accuracy >= 0.6 ? '⭐' : '💪'}
      </div>

      <p class={['text-5xl font-bold mb-2', getAccuracyColor(result.accuracy)].join(' ')}>
        {accuracyPercent}%
      </p>
      <p class="text-gray-500 mb-6">
        {result.correctAnswers} / {result.totalQuestions} 题正确
      </p>

      <div class="bg-gray-50 rounded-xl p-4 text-left space-y-3 mb-6">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">获得能量</span>
          <span class="font-bold text-amber-500">+{result.energyEarned}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">连续学习</span>
          <span class="font-bold text-gray-700">{result.streakMaintained ? '🔥 已保持' : '重新开始'}</span>
        </div>
        <div class="flex justify-between text-sm pt-2 border-t border-gray-200">
          <span class="text-gray-600">精灵反应</span>
          <span class="text-gray-700">{getSpiritMessage(result.spiritReaction)}</span>
        </div>
      </div>

      <!-- Adventure stats -->
      <div class="bg-gradient-to-r from-indigo-50 to-purple-50 rounded-xl p-3 text-xs space-y-1.5 mb-4">
        <div class="flex items-center justify-between gap-4 flex-wrap">
          <span class="text-gray-500"><span class="mr-1">🏁</span>冒险完成</span>
          <span class="text-gray-700 font-medium">⚡ 能量 {finalHp * 20}%</span>
        </div>
        <div class="flex items-center justify-between gap-4 flex-wrap">
          <span class="text-gray-500">🔥 最高 Combo</span>
          <span class="text-orange-500 font-bold">×{maxCombo > 1 ? (maxCombo >= 4 ? 2 : 1.5) : 1}</span>
        </div>
        <div class="flex items-center justify-between gap-4 flex-wrap">
          <span class="text-gray-500">🛡️ 守护者</span>
          <span class="{bossDefeated ? 'text-violet-600' : 'text-gray-500'} font-medium">{bossDefeated ? '✅ 已净化' : '💪 再接再厉'}</span>
        </div>
        <div class="flex items-center justify-between gap-4 flex-wrap">
          <span class="text-gray-500">💰 宝箱</span>
          <span class="text-amber-600 font-medium">{treasuresFound} 个</span>
        </div>
        {#if result.comboBonusEnergy > 0}
          <div class="flex items-center justify-between gap-4 flex-wrap pt-1 border-t border-indigo-200">
            <span class="text-gray-500">Combo 能量加成</span>
            <span class="text-amber-500 font-bold">+{result.comboBonusEnergy}</span>
          </div>
        {/if}
      </div>

      <button onclick={onclose}
              class="w-full py-3 bg-indigo-500 text-white rounded-lg font-semibold hover:bg-indigo-600 transition">
        返回地图
      </button>
    </div>
  {/if}
</div>
