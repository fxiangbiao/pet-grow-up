<script lang="ts">
  import { generateVariant } from '$lib/api/study';

  interface Props {
    nodeId: number;
    originalQuestionId: number;
    originalText: string;
    originalAnswer: string;
    subject: string;
    onComplete: (success: boolean) => void;
  }

  let { nodeId, originalQuestionId, originalText, originalAnswer, subject, onComplete }: Props = $props();

  let step = $state<'intro' | 'show_variant' | 'spirit_answer' | 'confirm' | 'result'>('intro');
  let variant = $state<any>(null);
  let variantAnswer = $state('');
  let spiritWrongAnswer = $state('');
  let loading = $state(false);
  let error = $state('');

  async function loadVariant() {
    loading = true;
    try {
      variant = await generateVariant(nodeId, originalQuestionId);
      step = 'show_variant';
    } catch (e: any) {
      error = e.message || 'Failed to load variant';
    } finally {
      loading = false;
    }
  }

  function spiritTryAnswer() {
    step = 'spirit_answer';
    // Spirit deliberately gives a wrong answer
    const correctAns = variant.correctAnswer;
    let wrong = correctAns;
    if (!isNaN(Number(correctAns))) {
      const num = parseInt(correctAns);
      wrong = String(num + (Math.random() > 0.5 ? 1 : -1));
    }
    spiritWrongAnswer = wrong;
  }

  function childConfirmsAnswer() {
    step = 'result';
  }

  function handleComplete(success: boolean) {
    onComplete(success);
  }
</script>

<div class="learn-by-analogy bg-white rounded-2xl shadow-lg p-5 border-2 border-amber-300">
  {#if step === 'intro'}
    <div class="text-center">
      <span class="text-4xl mb-3 block">馃</span>
      <h3 class="text-lg font-bold text-gray-800 mb-2">Can You Create a New Question?</h3>
      <p class="text-sm text-gray-600 mb-4">
        You just solved: <strong>{originalText}</strong>
      </p>
      <p class="text-sm text-gray-500 mb-4">
        Now try changing the numbers to make a new question!
      </p>
      <button onclick={loadVariant} disabled={loading}
        class="px-6 py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white font-bold rounded-xl hover:from-amber-500 hover:to-orange-600 transition active:scale-95 shadow-md disabled:opacity-50">
        {loading ? 'Loading...' : '鉁?Generate New Question'}
      </button>
    </div>

  {:else if step === 'show_variant' && variant}
    <div>
      <div class="bg-amber-50 rounded-xl p-4 mb-4">
        <p class="text-xs text-amber-600 font-medium mb-1">Original: {variant.originalText}</p>
        <p class="text-lg font-bold text-gray-800">New: {variant.questionText}</p>
      </div>

      <div class="mb-4">
        <label class="text-sm text-gray-600 mb-1 block">What's the answer?</label>
        <input type="text" bind:value={variantAnswer}
          placeholder="Type your answer..."
          class="w-full px-4 py-3 border-2 border-amber-300 rounded-xl focus:border-amber-500 outline-none transition text-lg" />
      </div>

      <div class="flex gap-2">
        <button onclick={spiritTryAnswer}
          class="px-4 py-3 bg-blue-100 text-blue-700 font-medium rounded-xl hover:bg-blue-200 transition text-sm">
          馃 Let Spirit Try
        </button>
        <button onclick={() => { step = 'result'; }} disabled={!variantAnswer}
          class="flex-1 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl disabled:from-gray-300 disabled:text-gray-400 transition active:scale-95">
          鉁?Confirm Answer
        </button>
      </div>
    </div>

  {:else if step === 'spirit_answer'}
    <div class="text-center">
      <div class="bg-blue-50 rounded-xl p-4 mb-4">
        <div class="flex items-center gap-2 mb-2">
          <span class="text-2xl">馃</span>
          <span class="text-sm font-medium text-blue-700">Spirit says:</span>
        </div>
        <p class="text-2xl font-bold text-blue-800">"I think the answer is {spiritWrongAnswer}!"</p>
      </div>
      <p class="text-sm text-gray-600 mb-4">
        Is the spirit correct? The correct answer should be: <strong>{variant.correctAnswer}</strong>
      </p>
      <div class="flex gap-2">
        <button onclick={() => { step = 'result'; }}
          class="flex-1 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl transition active:scale-95">
          馃槉 Good try! Let's continue
        </button>
      </div>
    </div>

  {:else if step === 'result'}
    <div class="text-center">
      <span class="text-5xl mb-3 block animate-bounce">馃帀</span>
      <h3 class="text-lg font-bold text-green-700 mb-2">Amazing Thinking!</h3>
      <p class="text-sm text-gray-600 mb-4">
        You created a new question and found the answer!
      </p>
      <p class="text-xs text-amber-600 mb-4">+8 energy earned!</p>
      <button onclick={() => handleComplete(true)}
        class="px-6 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold rounded-xl hover:from-green-600 hover:to-emerald-600 transition active:scale-95 shadow-md">
        Continue 鈫?
      </button>
    </div>
  {/if}

  {#if error}
    <div class="mt-3 bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">{error}</div>
  {/if}
</div>