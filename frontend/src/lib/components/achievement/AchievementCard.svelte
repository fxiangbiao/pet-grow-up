<script lang="ts">
  import type { UserAchievement } from '$lib/types/api';

  let { achievement, compact = false }: { achievement: UserAchievement; compact?: boolean } = $props();

  const rarityGradients: Record<string, string> = {
    COMMON: 'from-gray-100 to-gray-50 border-gray-200',
    RARE: 'from-blue-50 to-indigo-50 border-blue-200',
    EPIC: 'from-purple-50 to-violet-50 border-purple-200',
    LEGENDARY: 'from-amber-50 to-yellow-50 border-amber-200'
  };

  const rarityColors: Record<string, string> = {
    COMMON: 'text-gray-500',
    RARE: 'text-blue-600',
    EPIC: 'text-purple-600',
    LEGENDARY: 'text-amber-600'
  };

  const rarityBadges: Record<string, string> = {
    COMMON: 'bg-gray-100 text-gray-600',
    RARE: 'bg-blue-100 text-blue-700',
    EPIC: 'bg-purple-100 text-purple-700',
    LEGENDARY: 'bg-amber-100 text-amber-700'
  };

  const categoryIcons: Record<string, string> = {
    STUDY: '📚',
    SUBJECT: '📖',
    SPIRIT: '🐱',
    COLLECTION: '🏆',
    EVENT: '🎯',
    SOCIAL: '👥'
  };

  const rarityLabel: Record<string, string> = {
    COMMON: '普通',
    RARE: '稀有',
    EPIC: '史诗',
    LEGENDARY: '传说'
  };

  let def = $derived(achievement.definition);
  let rarity = $derived(def.rarity || 'COMMON');
  let isUnlocked = $derived(achievement.isUnlocked);
  let progressPct = $derived(
    def.requirementThreshold > 0
      ? Math.min(100, Math.round((achievement.currentValue / def.requirementThreshold) * 100))
      : 0
  );
  let borderGradient = $derived(rarityGradients[rarity] || rarityGradients.COMMON);
  let icon = $derived(categoryIcons[def.category] || '🏅');
</script>

<div
  class="rounded-2xl border-2 p-4 transition-all duration-300 {borderGradient} {isUnlocked ? 'opacity-100' : 'opacity-70'} {compact ? '' : 'hover:shadow-md'}"
  class:grayscale={!isUnlocked}
>
  <div class="flex items-start gap-3">
    <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-white shadow-sm flex items-center justify-center text-2xl">
      {icon}
    </div>
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2 flex-wrap">
        <h4 class="font-semibold text-sm text-gray-800 truncate">{def.name}</h4>
        {#if !compact}
          <span class="text-xs px-1.5 py-0.5 rounded {rarityBadges[rarity]}">{rarityLabel[rarity]}</span>
        {/if}
        {#if isUnlocked}
          <span class="text-green-500 text-xs font-medium">✓ 已解锁</span>
        {/if}
      </div>
      {#if !compact}
        <p class="text-xs text-gray-500 mt-1 line-clamp-2">{def.description}</p>
      {/if}

      {#if !isUnlocked && !compact}
        <div class="mt-2">
          <div class="flex justify-between text-xs text-gray-400 mb-1">
            <span>进度 {achievement.currentValue}/{def.requirementThreshold}</span>
            <span>{progressPct}%</span>
          </div>
          <div class="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
            <div
              class="h-full rounded-full transition-all duration-500 {rarityColors[rarity]}"
              style="width: {progressPct}%; background: currentColor; opacity: 0.5;"
            ></div>
          </div>
        </div>
      {/if}

      {#if isUnlocked && def.rewardEnergy > 0 && !compact}
        <p class="text-xs text-amber-600 mt-1">+{def.rewardEnergy} 能量奖励</p>
      {/if}
    </div>
  </div>
</div>
