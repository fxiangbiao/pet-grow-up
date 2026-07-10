<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let price = $state(3);
  let itemName = $state('');

  // Parse existing options JSON
  $effect(() => {
    try {
      if (questionData.options) {
        const opts = JSON.parse(questionData.options);
        price = opts.price || 3;
        itemName = opts.itemName || '';
      } else if (questionData.correctAnswer) {
        price = parseInt(questionData.correctAnswer) || 3;
      }
    } catch { /* ignore */ }
  });

  function sync() {
    onUpdate?.({ options: JSON.stringify({ price, itemName }), correctAnswer: String(price) });
  }

  function setPrice(p: number) { price = p; sync(); }
  function setItemName(n: string) { itemName = n; sync(); }
</script>

<div class="space-y-3">
  <p class="text-xs text-gray-400">宠物商店题型：学生用纸币/硬币凑出商品价格</p>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder='例如：请付 3 元买苹果'/>
  </div>
  <div class="grid grid-cols-2 gap-3">
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">商品名称</label>
      <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
             value={itemName}
             oninput={(e: Event) => setItemName((e.target as HTMLInputElement).value)}
             placeholder='例如：苹果'/>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">商品价格（元）</label>
      <select class="w-full px-3 py-1.5 border rounded-lg text-sm"
              value={price}
              onchange={(e: Event) => setPrice(Number((e.target as HTMLSelectElement).value))}>
        <option value="1">1 元</option>
        <option value="2">2 元</option>
        <option value="3">3 元</option>
        <option value="4">4 元</option>
        <option value="5">5 元</option>
        <option value="6">6 元</option>
        <option value="7">7 元</option>
        <option value="8">8 元</option>
        <option value="9">9 元</option>
        <option value="10">10 元</option>
      </select>
    </div>
  </div>
</div>
