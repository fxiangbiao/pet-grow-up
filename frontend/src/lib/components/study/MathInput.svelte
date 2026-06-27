<script lang="ts">
  let {
    disabled,
    onSelect
  }: {
    disabled: boolean;
    onSelect: (answer: string) => void;
  } = $props();

  let value = $state('');

  function handleInput() {
    if (value.trim()) {
      onSelect(value.trim());
    }
  }
</script>

<div>
  <input
    type="text"
    bind:value={value}
    oninput={handleInput}
    disabled={disabled}
    placeholder="输入你的答案..."
    class="w-full px-4 py-3 border-2 border-blue-200 rounded-xl text-lg text-center font-mono focus:border-blue-500 outline-none transition disabled:opacity-50"
    autocomplete="off"
  />
</div>
