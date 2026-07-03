<script lang="ts">
  // Picture book container — tabbed browsing of achievement albums

  let {
    activeTab = 'knowledge' as 'knowledge' | 'adventure' | 'spirit',
  }: {
    activeTab?: 'knowledge' | 'adventure' | 'spirit';
  } = $props();

  const tabs = [
    { key: 'knowledge', label: '知识点图鉴', icon: '📚', desc: '你学过的所有知识点' },
    { key: 'adventure', label: '闯关图鉴', icon: '🏆', desc: '冒险记录与最高成就' },
    { key: 'spirit', label: '星灵图鉴', icon: '🐱', desc: '星灵成长与进化历程' },
  ] as const;
</script>

<div class="bg-white rounded-2xl shadow-sm p-6">
  <!-- Tab bar -->
  <div class="flex gap-2 mb-6">
    {#each tabs as tab}
      <button
        onclick={() => activeTab = tab.key}
        class="flex-1 py-3 px-2 rounded-xl text-center transition
          {activeTab === tab.key
            ? 'bg-indigo-100 text-indigo-700 shadow-sm'
            : 'bg-gray-50 text-gray-500 hover:bg-gray-100'}"
      >
        <div class="text-lg">{tab.icon}</div>
        <div class="text-xs font-semibold mt-1">{tab.label}</div>
      </button>
    {/each}
  </div>

  <!-- Content slot -->
  <div class="min-h-[200px]">
    {#if activeTab === 'knowledge'}
      <slot name="knowledge">
        <p class="text-gray-400 text-center py-12">知识点图鉴内容</p>
      </slot>
    {:else if activeTab === 'adventure'}
      <slot name="adventure">
        <p class="text-gray-400 text-center py-12">闯关图鉴内容</p>
      </slot>
    {:else}
      <slot name="spirit">
        <p class="text-gray-400 text-center py-12">星灵图鉴内容</p>
      </slot>
    {/if}
  </div>
</div>
