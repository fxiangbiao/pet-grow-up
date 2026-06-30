<script lang="ts">
  import { submitAnswer, type QuestionDTO, type AnswerResult } from '$lib/api/study';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    question,
    sessionId,
    onComplete
  }: {
    question: QuestionDTO;
    sessionId: number;
    onComplete: (result: AnswerResult) => void;
  } = $props();

  // ── Bill definitions ──
  interface Bill {
    id: string;
    value: number;
    emoji: string;
    label: string;
  }

  const WALLET_BILLS: Bill[] = [
    { id: 'y1_1', value: 1, emoji: '💵', label: '1元' },
    { id: 'y1_2', value: 1, emoji: '💵', label: '1元' },
    { id: 'y1_3', value: 1, emoji: '💵', label: '1元' },
    { id: 'y1_4', value: 1, emoji: '💵', label: '1元' },
    { id: 'y1_5', value: 1, emoji: '💵', label: '1元' },
    { id: 'y5_1', value: 5, emoji: '💰', label: '5元' },
    { id: 'y5_2', value: 5, emoji: '💰', label: '5元' },
    { id: 'y5_3', value: 5, emoji: '💰', label: '5元' },
    { id: 'y10_1', value: 10, emoji: '💎', label: '10元' },
    { id: 'y10_2', value: 10, emoji: '💎', label: '10元' },
  ];

  // Parse target price from question
  function parseTargetPrice(): number {
    const opts = question.options;
    let raw: any = opts;
    if (typeof opts === 'string') {
      try { raw = JSON.parse(opts); } catch { raw = {}; }
    }
    if (Array.isArray(raw)) return parseInt(raw[0]?.key) || 3;
    if (typeof raw === 'object' && raw !== null) return parseInt((raw as any).price || (raw as any).key) || 3;
    return 3;
  }

  const targetPrice = $state(parseTargetPrice());
  const itemName = $derived.by(() => {
    const opts = question.options;
    let raw: any = opts;
    if (typeof opts === 'string') {
      try { raw = JSON.parse(opts); } catch { raw = {}; }
    }
    if (typeof raw === 'object' && raw !== null) return (raw as any).itemName || (raw as any).text || '宠物零食';
    return '宠物零食';
  });

  // Shop item emojis by price
  const itemEmoji: Record<number, string> = { 1: '🍭', 2: '🍎', 3: '🍪', 4: '🧃', 5: '🍩', 6: '🧸', 7: '🎨', 8: '📚', 9: '🎁', 10: '🎂' };

  let walletBills = $state<Bill[]>([]);
  let paidBills = $state<Bill[]>([]);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);
  let showSuccess = $state(false);

  const paidAmount = $derived(paidBills.reduce((sum, b) => sum + b.value, 0));
  const isExact = $derived(paidAmount === targetPrice);
  const isOver = $derived(paidAmount > targetPrice);

  // Init
  $effect(() => {
    walletBills = [...WALLET_BILLS].sort(() => Math.random() - 0.5);
  });

  // ── Drag and drop ──
  let dragBillId = $state<string | null>(null);

  function handleDragStart(billId: string) {
    if (submitted) return;
    dragBillId = billId;
  }

  function handleDropOnPayment(e: DragEvent) {
    e.preventDefault();
    if (!dragBillId || submitted) return;
    const bill = walletBills.find(b => b.id === dragBillId);
    if (!bill) { dragBillId = null; return; }
    walletBills = walletBills.filter(b => b.id !== bill.id);
    paidBills = [...paidBills, bill];
    soundManager.playCoinDrop();
    dragBillId = null;
  }

  function handleDragOver(e: DragEvent) {
    e.preventDefault();
  }

  function handleDragEnd() {
    dragBillId = null;
  }

  // Tap to pay
  function tapBill(billId: string) {
    if (submitted) return;
    const bill = walletBills.find(b => b.id === billId);
    if (!bill) return;
    walletBills = walletBills.filter(b => b.id !== bill.id);
    paidBills = [...paidBills, bill];
    soundManager.playCoinDrop();
  }

  function removeBill(billId: string) {
    if (submitted) return;
    const bill = paidBills.find(b => b.id === billId);
    if (!bill) return;
    paidBills = paidBills.filter(b => b.id !== bill.id);
    walletBills = [...walletBills, bill];
  }

  async function handlePay() {
    if (!isExact || submitted) return;
    submitted = true;
    soundManager.playPurchase();

    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: String(targetPrice),
        timeSpent: 0
      });
      if (result) {
        feedback = 'correct';
        showFeedback = true;
        showSuccess = true;
        soundManager.playCorrect();
        soundManager.playPetEat();
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('[Shop] onComplete failed:', e); }
        }, 1800);
      }
    } catch (err) {
      console.error('[Shop] Submit failed:', err);
      submitted = false;
      feedback = 'idle';
      showFeedback = false;
      showSuccess = false;
    }
  }

  function handleReset() {
    if (submitted) return;
    walletBills = [...walletBills, ...paidBills].sort(() => Math.random() - 0.5);
    paidBills = [];
  }
</script>

<div
  class="relative w-full min-h-[440px] bg-gradient-to-b from-yellow-50 via-amber-50 to-orange-100 overflow-hidden select-none rounded-xl"
  style="touch-action: manipulation;"
  role="application"
  aria-label="宠物商店付款"
>
  <!-- Hint -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-amber-800 bg-white/80 rounded-full px-5 py-1.5 shadow-sm">
      🐱「{question.questionText || `请付 ${targetPrice} 元买${itemName}！`}」
    </p>
  </div>

  <div class="absolute inset-x-0 top-16 bottom-4 px-3 flex flex-col gap-3">
    <!-- Shelf: item + price tag -->
    <div class="flex items-center justify-center gap-3 bg-white/70 rounded-2xl p-3 border-2 border-amber-200">
      <div class="text-5xl">{itemEmoji[targetPrice] || '🎁'}</div>
      <div class="text-center">
        <p class="text-sm font-semibold text-gray-600">{itemName}</p>
        <p class="text-2xl font-black text-amber-600">¥{targetPrice}</p>
      </div>
    </div>

    <!-- Payment tray (drop zone) -->
    <div
      ondrop={handleDropOnPayment}
      ondragover={handleDragOver}
      class={[
        'flex-1 min-h-[90px] bg-white/60 rounded-2xl border-2 border-dashed p-3 flex flex-wrap items-start gap-2 content-start',
        isExact ? 'border-green-400 bg-green-50' : isOver ? 'border-red-300 bg-red-50' : 'border-amber-300',
      ].join(' ')}
    >
      <p class="w-full text-xs text-gray-400 text-center mb-1">💰 付款区 — 把纸币拖到这里</p>
      {#each paidBills as bill (bill.id + '_paid')}
        <button
          onclick={() => removeBill(bill.id)}
          disabled={submitted}
          class="px-2 py-1 bg-white rounded-lg border-2 border-amber-400 shadow-sm text-lg
            hover:scale-110 active:scale-95 transition cursor-pointer"
          aria-label={'移除' + bill.label}>
          {bill.emoji}
          <span class="text-xs font-bold text-amber-700 ml-0.5">{bill.value}元</span>
        </button>
      {/each}
      <!-- Total display -->
      {#if paidBills.length > 0}
        <div class={[
          'ml-auto text-lg font-black px-3 py-1 rounded-lg self-end',
          isExact ? 'text-green-600 bg-green-100' : isOver ? 'text-red-600 bg-red-100' : 'text-amber-600 bg-amber-100',
        ].join(' ')}>
          合计: ¥{paidAmount}
          {#if isOver}<span class="text-xs ml-1">多了 ¥{paidAmount - targetPrice}</span>{/if}
        </div>
      {/if}
    </div>

    <!-- Wallet area -->
    <div class="bg-white/70 rounded-2xl p-3 border-2 border-amber-200">
      <p class="text-xs text-gray-400 mb-2">👛 我的钱包 — 点击或拖拽纸币付款</p>
      <div class="flex flex-wrap gap-2">
        {#each walletBills as bill (bill.id)}
          <button
            draggable="true"
            ondragstart={() => handleDragStart(bill.id)}
            ondragend={handleDragEnd}
            onclick={() => tapBill(bill.id)}
            disabled={submitted}
            class="px-2 py-1 bg-amber-50 rounded-lg border-2 border-amber-300 shadow-sm text-lg
              hover:scale-110 active:scale-95 transition cursor-pointer hover:bg-amber-100"
            aria-label={bill.label}>
            {bill.emoji}
            <span class="text-xs font-bold text-amber-700 ml-0.5">{bill.value}元</span>
          </button>
        {/each}
      </div>
    </div>

    <!-- Action buttons -->
    <div class="flex gap-2">
      {#if !submitted}
        <button onclick={handleReset}
          class="px-4 py-2 bg-gray-200 text-gray-700 rounded-xl text-sm font-medium hover:bg-gray-300 transition">
          🔄 重新来
        </button>
        <button onclick={handlePay}
          disabled={!isExact}
          class="flex-1 py-2.5 bg-gradient-to-r from-amber-400 to-orange-500 text-white rounded-xl font-bold
            hover:from-amber-300 hover:to-orange-400 disabled:from-gray-300 disabled:to-gray-300 disabled:text-gray-400
            transition shadow-md">
          {isOver ? '💰 太多了，退回一些' : isExact ? '✅ 付款！' : `还差 ¥${targetPrice - paidAmount}`}
        </button>
      {/if}
    </div>
  </div>

  <!-- Success overlay -->
  {#if showSuccess}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in text-center">
        🛍️ 购买成功！<br />
        <span class="text-lg font-normal">{itemName} 送给宠物啦～</span>
      </div>
    </div>
  {/if}
</div>

<style lang="postcss">
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    50% { transform: scale(1.1); }
    70% { transform: scale(0.9); }
    100% { transform: scale(1); opacity: 1; }
  }
  :global(.animate-bounce-in) {
    animation: bounceIn 0.5s ease-out;
  }
</style>
