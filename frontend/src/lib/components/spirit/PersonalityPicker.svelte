<script lang="ts">
  let {
    selected = $bindable<string>('')
  }: {
    selected?: string;
  } = $props();

  const personalities = [
    {
      key: 'cheerful',
      name: '元气活泼',
      emoji: '🎉',
      glow: 'shadow-orange-400/50',
      border: 'border-orange-400',
      bg: 'bg-orange-50',
      desc: '轻快热闹，超兴奋！',
      quote: '耶！今天学什么？冲冲冲！',
      dims: '活泼 80 · 调皮 70',
      color: 'from-amber-400 to-orange-500'
    },
    {
      key: 'gentle',
      name: '温柔治愈',
      emoji: '🌸',
      glow: 'shadow-pink-400/50',
      border: 'border-pink-400',
      bg: 'bg-pink-50',
      desc: '软萌鼓励，暖到心里',
      quote: '没关系的，我一直在你身边',
      dims: '温柔 85 · 害羞 55',
      color: 'from-pink-400 to-rose-500'
    },
    {
      key: 'tsundere',
      name: '傲娇呆萌',
      emoji: '😤',
      glow: 'shadow-purple-400/50',
      border: 'border-purple-400',
      bg: 'bg-purple-50',
      desc: '嘴硬心软，死傲娇',
      quote: '哼！才不是专门等你的...',
      dims: '独立 70 · 害羞 60',
      color: 'from-violet-400 to-purple-500'
    },
    {
      key: 'brave',
      name: '勇敢冒险',
      emoji: '⚔️',
      glow: 'shadow-red-400/50',
      border: 'border-red-400',
      bg: 'bg-red-50',
      desc: '热血沸腾，中二魂燃！',
      quote: '我们一起打败所有难题！',
      dims: '勇敢 85 · 活泼 65',
      color: 'from-red-400 to-rose-500'
    }
  ];

  let previewKey = $state<string | null>(null);
  let previewVisible = $state(false);

  function preview(key: string) {
    previewKey = key;
    previewVisible = true;
  }

  function hidePreview() {
    previewVisible = false;
    setTimeout(() => { previewKey = null; }, 200);
  }
</script>

<div class="space-y-3">
  <h3 class="text-center text-gray-700 font-semibold text-lg">选择星灵的性格</h3>
  <p class="text-center text-gray-400 text-sm -mt-1">性格会影响星灵对你的说话方式哦</p>

  <div class="grid grid-cols-2 gap-3 mt-4">
    {#each personalities as p}
      <button
        onclick={() => { selected = p.key; preview(p.key); }}
        onmouseenter={() => preview(p.key)}
        onmouseleave={hidePreview}
        class={[
          'relative rounded-xl p-4 border-2 text-left transition-all duration-300',
          'hover:shadow-lg hover:scale-[1.03]',
          selected === p.key
            ? [p.border, p.bg, p.glow, 'shadow-lg scale-[1.02]'].join(' ')
            : 'border-gray-200 bg-white hover:border-gray-300'
        ].join(' ')}
      >
        <!-- Selected check -->
        {#if selected === p.key}
          <div class="absolute top-2 right-2 w-5 h-5 rounded-full bg-gradient-to-br {p.color} flex items-center justify-center">
            <span class="text-white text-xs">✓</span>
          </div>
        {/if}

        <div class="text-3xl mb-1.5">{p.emoji}</div>
        <div class="font-bold text-gray-800 text-sm">{p.name}</div>
        <div class="text-xs text-gray-400 mt-0.5">{p.desc}</div>
        <div class="text-[10px] text-gray-300 mt-1">{p.dims}</div>
      </button>
    {/each}
  </div>

  <!-- Preview bubble -->
  {#if previewVisible && previewKey}
    {@const p = personalities.find(x => x.key === previewKey)!}
    <div class="mt-4 transition-all duration-200 animate-fade-in p-4 rounded-xl bg-gradient-to-r {p.color} text-white text-center">
      <p class="text-sm font-medium">「{p.name}」星灵会说：</p>
      <p class="mt-1.5 text-base italic">"{p.quote}"</p>
    </div>
  {/if}
</div>

<style>
  @keyframes fadeIn {
    0% { opacity: 0; transform: translateY(4px); }
    100% { opacity: 1; transform: translateY(0); }
  }
  :global(.animate-fade-in) {
    animation: fadeIn 0.25s ease-out;
  }
</style>
