<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores/auth.svelte';
  import { achievementStore } from '$lib/stores/achievement.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import SpiritGreeting from '$lib/components/spirit/SpiritGreeting.svelte';

  onMount(() => {
    achievementStore.refresh();
    spiritStore.refresh(authStore.user!.id);
    spiritStore.checkStatus();
  });

  function spiritMood(): 'happy' | 'excited' | 'hurt' | 'idle' | undefined {
    const s = spiritStore.activeSpirit;
    if (!s) return undefined;
    if (spiritStore.dormancyLevel >= 2) return undefined; // sleeping, handled separately
    if (spiritStore.dormancyLevel >= 1) return 'hurt';
    if (s.happiness >= 80) return 'excited';
    if (s.happiness >= 50) return 'happy';
    return 'idle';
  }
</script>

<svelte:head>
  <title>仪表盘 - Pet Grow Up</title>
</svelte:head>

{#if authStore.user}
  <div class="space-y-6 animate-slide-up">
    <!-- Sprint C: Spirit greeting banner (shown after returning) -->
    {#if spiritStore.showGreeting && spiritStore.activeSpirit}
      <SpiritGreeting
        species={spiritStore.activeSpirit.species}
        personality={spiritStore.personalityType as any}
        nickname={spiritStore.activeSpirit.nickname}
        dormancyLevel={spiritStore.dormancyLevel}
        onDismiss={() => spiritStore.dismissGreeting()}
      />
    {/if}

    <!-- Hero card: user greeting + active spirit -->
    <div class="bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-2xl shadow-lg p-6 text-white">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <h1 class="text-2xl font-bold">你好，{authStore.user.nickname}！</h1>
          <p class="text-white/80 mt-1">今天也要加油学习哦！</p>

          <div class="mt-4 flex flex-wrap gap-3">
            <div class="bg-white/20 backdrop-blur-sm rounded-xl px-4 py-2.5">
              <span class="text-xs text-white/70">学习能量</span>
              <div class="flex items-center gap-2">
                <span class="text-2xl font-bold">{authStore.user.currentEnergy}</span>
                <span class="text-lg">⚡</span>
              </div>
            </div>
            {#if spiritStore.activeSpirit}
              <div class="bg-white/20 backdrop-blur-sm rounded-xl px-4 py-2.5">
                <span class="text-xs text-white/70">连续学习</span>
                <div class="flex items-center gap-1.5">
                  <span class="text-2xl font-bold">{authStore.user.consecutiveStudyDays ?? '—'}</span>
                  <span class="text-lg">🔥</span>
                </div>
              </div>
            {/if}
          </div>
        </div>

        {#if spiritStore.activeSpirit}
          <button onclick={() => goto('/app/spirit')}
                class="flex-shrink-0 -mt-2 -mr-2 p-2 rounded-full hover:bg-white/10 transition">
            <SpiritAvatar
              species={spiritStore.activeSpirit.species}
              evolutionStage={spiritStore.activeSpirit.currentEvolutionStage}
              mood={spiritMood()}
              size="lg"
            />
          </button>
        {:else}
          <a href="/app/spirit/choose"
             class="flex-shrink-0 bg-white/20 backdrop-blur-sm rounded-2xl px-4 py-3 text-center hover:bg-white/30 transition">
            <div class="text-3xl mb-1">🐣</div>
            <div class="text-xs font-medium">选择你的精灵</div>
          </a>
        {/if}
      </div>

      <!-- Spirit status bars -->
      {#if spiritStore.activeSpirit}
        <div class="mt-4 grid grid-cols-3 gap-3">
          <div>
            <div class="flex justify-between text-xs text-white/70 mb-1">
              <span>好感度</span>
              <span>{spiritStore.activeSpirit.affection}</span>
            </div>
            <div class="h-2 bg-white/20 rounded-full overflow-hidden">
              <div class="h-full bg-pink-300 rounded-full transition-all duration-1000"
                   style="width: {Math.min(spiritStore.activeSpirit.affection, 100)}%"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-white/70 mb-1">
              <span>快乐值</span>
              <span>{spiritStore.activeSpirit.happiness}</span>
            </div>
            <div class="h-2 bg-white/20 rounded-full overflow-hidden">
              <div class="h-full bg-yellow-300 rounded-full transition-all duration-1000"
                   style="width: {spiritStore.activeSpirit.happiness}%"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-white/70 mb-1">
              <span>精力</span>
              <span>{spiritStore.activeSpirit.energy}</span>
            </div>
            <div class="h-2 bg-white/20 rounded-full overflow-hidden">
              <div class="h-full bg-green-300 rounded-full transition-all duration-1000"
                   style="width: {spiritStore.activeSpirit.energy}%"></div>
            </div>
          </div>
        </div>
        <div class="mt-2 text-xs text-white/60">
          {spiritStore.activeSpirit.nickname} · {spiritStore.activeSpirit.species.name}
          {#if spiritStore.activeSpirit.currentEvolutionStage > 1}
            · 进化 x{spiritStore.activeSpirit.currentEvolutionStage}
          {/if}
        </div>
      {/if}
    </div>

    <!-- Quick navigation cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
      <a href="/app/study" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mb-3">📚</div>
        <h3 class="font-semibold text-gray-800">开始学习</h3>
        <p class="text-sm text-gray-500 mt-1">进入学科世界探险</p>
      </a>
      <a href="/app/spirit" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mb-3">🐱</div>
        <h3 class="font-semibold text-gray-800">我的精灵</h3>
        <p class="text-sm text-gray-500 mt-1">查看精灵状态和成长</p>
      </a>
      <a href="/app/achievements" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mb-3">🏆</div>
        <h3 class="font-semibold text-gray-800">成就</h3>
        <p class="text-sm text-gray-500 mt-1">
          {achievementStore.unlockedCount}/{achievementStore.totalCount} 已解锁
        </p>
      </a>
      <a href="/app/social" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-pink-100 rounded-xl flex items-center justify-center mb-3">👥</div>
        <h3 class="font-semibold text-gray-800">社交</h3>
        <p class="text-sm text-gray-500 mt-1">查看好友和排行榜</p>
      </a>
      <a href="/app/shop" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center mb-3">🛒</div>
        <h3 class="font-semibold text-gray-800">商店</h3>
        <p class="text-sm text-gray-500 mt-1">购买物品帮助精灵成长</p>
      </a>
      <a href="/app/daily" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center mb-3">📅</div>
        <h3 class="font-semibold text-gray-800">每日</h3>
        <p class="text-sm text-gray-500 mt-1">完成挑战赢取能量</p>
      </a>
      <a href="/app/story" class="bg-white rounded-2xl shadow-sm p-6 hover:shadow-md hover:-translate-y-0.5 transition-all cursor-pointer">
        <div class="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center mb-3">📖</div>
        <h3 class="font-semibold text-gray-800">剧情</h3>
        <p class="text-sm text-gray-500 mt-1">探索学习能量宇宙</p>
      </a>
    </div>
  </div>
{/if}
