<script lang="ts">
  import { onMount } from 'svelte';
  import type { WeaknessDTO } from '$lib/types/api';

  let {
    weaknesses = []
  }: {
    weaknesses?: WeaknessDTO[];
  } = $props();

  const subjectLabels: Record<string, string> = {
    math: '数学',
    chinese: '语文',
    english: '英语'
  };

  const subjectColors: Record<string, string> = {
    math: 'bg-blue-50 text-blue-700 border-blue-200',
    chinese: 'bg-red-50 text-red-700 border-red-200',
    english: 'bg-green-50 text-green-700 border-green-200'
  };

  function masteryColor(level: number): string {
    if (level >= 60) return 'bg-emerald-400';
    if (level >= 30) return 'bg-amber-400';
    return 'bg-red-400';
  }
</script>

<div class="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm">
  <h3 class="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-1.5">
    <span>📚</span> 学习档案
  </h3>

  {#if weaknesses.length === 0}
    <div class="text-center text-gray-400 text-xs py-4">
      暂无薄弱知识点，继续保持学习吧！
    </div>
  {:else}
    <div class="space-y-3">
      {#each weaknesses as w}
        <div class="flex items-center gap-3">
          <span class="text-xs px-2 py-0.5 rounded-full border {subjectColors[w.subject] || 'bg-gray-50 text-gray-600 border-gray-200'}">
            {subjectLabels[w.subject] || w.subject}
          </span>
          <div class="flex-1 min-w-0">
            <div class="text-xs text-gray-700 truncate">{w.knowledgeNodeName}</div>
            <div class="flex items-center gap-2 mt-1">
              <div class="flex-1 bg-gray-100 rounded-full h-1.5 overflow-hidden">
                <div
                  class="h-1.5 rounded-full transition-all duration-500 {masteryColor(w.masteryLevel)}"
                  style="width: {w.masteryLevel}%"
                ></div>
              </div>
              <span class="text-[10px] text-gray-400">{w.masteryLevel}%</span>
            </div>
          </div>
          <span class="text-[10px] text-gray-400 whitespace-nowrap">错{w.wrongCount}次</span>
        </div>
      {/each}
    </div>
  {/if}
</div>
