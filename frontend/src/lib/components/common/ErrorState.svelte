<script lang="ts">
  let {
    type = 'server',
    message = '',
    onRetry,
    onAction,
    actionLabel = ''
  }: {
    type?: 'network' | 'auth' | 'server' | 'empty';
    message?: string;
    onRetry?: () => void;
    onAction?: () => void;
    actionLabel?: string;
  } = $props();

  const config: Record<string, { icon: string; title: string; desc: string }> = {
    network: { icon: '📡', title: '网络连接失败', desc: '请检查网络连接后重试' },
    auth: { icon: '🔒', title: '登录已过期', desc: '请重新登录以继续操作' },
    server: { icon: '⚙️', title: '服务暂时不可用', desc: '请稍后再试' },
    empty: { icon: '📭', title: '暂无数据', desc: '这里还没有任何内容' }
  };

  let current = $derived(config[type] || config.server);
</script>

<div class="flex flex-col items-center justify-center py-12 text-center max-w-sm mx-auto">
  <div class="text-5xl mb-4 opacity-70">{current.icon}</div>
  <h3 class="text-lg font-semibold text-gray-700 mb-1">{current.title}</h3>
  <p class="text-sm text-gray-400 mb-6">{message || current.desc}</p>

  <div class="flex gap-3">
    {#if onRetry}
      <button
        onclick={onRetry}
        class="px-6 py-2.5 bg-indigo-500 text-white rounded-xl text-sm font-medium hover:bg-indigo-600 transition shadow-sm"
      >
        重试
      </button>
    {/if}
    {#if type === 'auth'}
      <a href="/login"
         class="px-6 py-2.5 bg-indigo-500 text-white rounded-xl text-sm font-medium hover:bg-indigo-600 transition shadow-sm">
        重新登录
      </a>
    {/if}
    {#if onAction && actionLabel}
      <button
        onclick={onAction}
        class="px-6 py-2.5 bg-white text-indigo-600 rounded-xl text-sm font-medium border border-indigo-200 hover:bg-indigo-50 transition"
      >
        {actionLabel}
      </button>
    {/if}
  </div>
</div>