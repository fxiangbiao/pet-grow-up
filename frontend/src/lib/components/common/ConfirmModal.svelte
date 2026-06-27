<script lang="ts">
  let {
    show = false,
    title = '确认操作',
    message = '你确定要执行此操作吗？',
    confirmText = '确定',
    cancelText = '取消',
    onConfirm = () => {},
    onCancel = () => {}
  }: {
    show?: boolean;
    title?: string;
    message?: string;
    confirmText?: string;
    cancelText?: string;
    onConfirm?: () => void;
    onCancel?: () => void;
  } = $props();
</script>

{#if show}
  <!-- Overlay -->
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm animate-fade-in"
       onclick={onCancel} role="presentation">
    <!-- Dialog -->
    <!-- svelte-ignore a11y_interactive_supports_focus a11y_click_events_have_key_events -->
    <div class="bg-white rounded-2xl shadow-xl p-6 max-w-sm mx-4 animate-scale-in"
         onclick={(e) => e.stopPropagation()} role="dialog">
      <h3 class="text-lg font-bold text-gray-800 mb-2">{title}</h3>
      <p class="text-gray-600 text-sm mb-6">{message}</p>
      <div class="flex gap-3 justify-end">
        <button onclick={onCancel}
                class="px-4 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200 transition">
          {cancelText}
        </button>
        <button onclick={onConfirm}
                class="px-4 py-2 text-sm text-white bg-red-500 rounded-lg hover:bg-red-600 transition shadow-sm">
          {confirmText}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  :global(.animate-fade-in) {
    animation: fade-in 0.2s ease-out;
  }
  @keyframes scale-in {
    0% { opacity: 0; transform: scale(0.9); }
    100% { opacity: 1; transform: scale(1); }
  }
  :global(.animate-scale-in) {
    animation: scale-in 0.2s ease-out;
  }
</style>
