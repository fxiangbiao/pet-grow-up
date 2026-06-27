<script lang="ts">
  import type { ItemDef } from '$lib/types/api';

  let {
    item,
    onBuy
  }: {
    item: ItemDef;
    onBuy: (item: ItemDef) => void;
  } = $props();

  const categoryIcons: Record<string, string> = {
    FOOD: '🍬',
    TOY: '🧸',
    DECORATION: '🎨',
    CONSUMABLE: '🧪'
  };

  const typeLabels: Record<string, string> = {
    HAPPINESS: '快乐度',
    ENERGY: '精力',
    AFFECTION: '亲密度'
  };
</script>

<div class="bg-white rounded-xl border border-gray-100 p-4 hover:shadow-md transition cursor-pointer">
  <div class="text-3xl mb-2">{categoryIcons[item.category] || '📦'}</div>
  <h3 class="font-semibold text-gray-800 text-sm">{item.name}</h3>
  <p class="text-xs text-gray-400 mt-1">{item.description}</p>
  <div class="mt-2 text-xs text-indigo-500">
    +{item.effectValue} {typeLabels[item.effectType] || item.effectType}
  </div>
  <div class="flex items-center justify-between mt-3">
    <span class="text-sm font-bold text-amber-500">⚡{item.price}</span>
    <button
      onclick={() => onBuy(item)}
      class="px-3 py-1 text-xs bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition"
    >
      购买
    </button>
  </div>
</div>
