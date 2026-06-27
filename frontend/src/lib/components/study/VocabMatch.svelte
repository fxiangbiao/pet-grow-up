<script lang="ts">
  let {
    options,
    disabled,
    onSelect
  }: {
    options: { left: Array<{ id: string; text: string }>; right: Array<{ id: string; text: string }> };
    disabled: boolean;
    onSelect: (answer: string) => void;
  } = $props();

  let selectedLeft = $state<string | null>(null);
  let pairs = $state<Array<{ leftId: string; rightId: string }>>([]);
  let availableRight = $state<string[]>([]);

  $effect(() => {
    availableRight = options.right.map(r => r.id);
    selectedLeft = null;
    pairs = [];
  });

  function selectLeft(id: string) {
    if (disabled) return;
    selectedLeft = id;
  }

  function selectRight(id: string) {
    if (disabled || !selectedLeft) return;
    pairs = [...pairs, { leftId: selectedLeft, rightId: id }];
    availableRight = availableRight.filter(r => r !== id);
    selectedLeft = null;

    if (pairs.length === options.left.length) {
      const answer = pairs.map(p => `${p.leftId}${p.rightId}`).join(',');
      onSelect(answer);
    }
  }

  function resetPair() {
    if (disabled) return;
    if (pairs.length === 0) return;
    const last = pairs[pairs.length - 1];
    pairs = pairs.slice(0, -1);
    availableRight = [...availableRight, last.rightId];
  }

  function getPairedRight(leftId: string): string | undefined {
    return pairs.find(p => p.leftId === leftId)?.rightId;
  }

  function getRightText(rightId: string): string {
    return options.right.find(r => r.id === rightId)?.text || '';
  }
</script>

<div class="space-y-4">
  <div class="flex justify-between items-center">
    <span class="text-xs text-gray-400">点击左边的单词，再点击右边对应的释义</span>
    {#if pairs.length > 0}
      <button
        onclick={resetPair}
        disabled={disabled}
        class="text-xs text-gray-400 hover:text-gray-600 transition"
      >
        撤销配对
      </button>
    {/if}
  </div>

  <div class="flex gap-8 justify-center items-start">
    <!-- Left column: English words -->
    <div class="space-y-2">
      {#each options.left as item}
        {@const pairedRight = getPairedRight(item.id)}
        <button
          onclick={() => selectLeft(item.id)}
          disabled={disabled || pairedRight !== undefined}
          class={[
            'w-28 px-4 py-3 rounded-xl text-sm font-medium border-2 transition text-center',
            pairedRight
              ? 'bg-gray-100 border-gray-200 text-gray-400 cursor-default'
              : selectedLeft === item.id
                ? 'bg-indigo-100 border-indigo-500 text-indigo-700'
                : 'bg-white border-gray-200 text-gray-700 hover:border-indigo-300'
          ].join(' ')}
        >
          {item.text}
        </button>
      {/each}
    </div>

    <!-- Connection lines -->
    <div class="flex flex-col justify-around py-2 space-y-2">
      {#each options.left as item}
        {@const pairedRight = getPairedRight(item.id)}
        <div class="flex items-center">
          {#if pairedRight}
            <span class="text-lg text-green-500">←→</span>
          {:else}
            <span class="text-lg text-gray-300">···</span>
          {/if}
        </div>
      {/each}
    </div>

    <!-- Right column: Chinese meanings -->
    <div class="space-y-2">
      {#each options.right as item}
        <button
          onclick={() => selectRight(item.id)}
          disabled={disabled || !selectedLeft || !availableRight.includes(item.id)}
          class={[
            'w-28 px-4 py-3 rounded-xl text-sm font-medium border-2 transition text-center',
            !availableRight.includes(item.id)
              ? 'bg-gray-100 border-gray-200 text-gray-400 cursor-default'
              : selectedLeft
                ? 'bg-white border-gray-200 text-gray-700 hover:border-green-400 hover:bg-green-50'
                : 'bg-white border-gray-200 text-gray-400 cursor-default'
          ].join(' ')}
        >
          {item.text}
        </button>
      {/each}
    </div>
  </div>

  {#if pairs.length > 0 && pairs.length < options.left.length}
    <p class="text-xs text-gray-400 text-center">
      已配对 {pairs.length}/{options.left.length} 组
    </p>
  {/if}
</div>
