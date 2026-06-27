<script lang="ts">
  let {
    options,
    disabled,
    onSelect
  }: {
    options: string[];
    disabled: boolean;
    onSelect: (answer: string) => void;
  } = $props();

  let remaining = $state<string[]>([]);
  let selected = $state<string[]>([]);

  $effect(() => {
    remaining = [...options];
    selected = [];
  });

  function pickLine(line: string) {
    if (disabled) return;
    remaining = remaining.filter(l => l !== line);
    selected = [...selected, line];
    if (selected.length === options.length) {
      const answer = selected.map(line => options.indexOf(line) + 1).join(',');
      onSelect(answer);
    }
  }

  function unpickLine(line: string) {
    if (disabled) return;
    selected = selected.filter(l => l !== line);
    remaining = [...remaining, line];
  }
</script>

<div class="space-y-4">
  {#if selected.length > 0}
    <div class="min-h-[80px] bg-amber-50 border-2 border-dashed border-amber-300 rounded-xl p-4">
      <p class="text-xs text-amber-500 mb-2">已选择的顺序：</p>
      <div class="flex flex-wrap gap-2">
        {#each selected as line, i}
          <button
            onclick={() => unpickLine(line)}
            disabled={disabled}
            class="px-4 py-2 bg-amber-100 text-amber-800 rounded-lg text-sm hover:bg-amber-200 transition disabled:opacity-50"
          >
            <span class="font-mono text-xs text-amber-400 mr-1">{i + 1}.</span>
            {line}
          </button>
        {/each}
      </div>
    </div>
  {:else}
    <div class="min-h-[80px] bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-4 flex items-center justify-center">
      <p class="text-sm text-gray-400">点击下方诗句按正确顺序排列</p>
    </div>
  {/if}

  <div class="flex flex-wrap gap-2 justify-center">
    {#each remaining as line}
      <button
        onclick={() => pickLine(line)}
        disabled={disabled}
        class="px-4 py-2.5 bg-white border border-amber-200 text-amber-900 rounded-lg text-sm hover:bg-amber-50 hover:border-amber-300 transition disabled:opacity-50"
      >
        {line}
      </button>
    {/each}
  </div>

  {#if selected.length > 0 && selected.length < options.length}
    <p class="text-xs text-gray-400 text-center">
      已选 {selected.length}/{options.length} 句
    </p>
  {/if}
</div>
