<script lang="ts">
  import { onDestroy } from 'svelte';
  import { startListening, isSpeechRecognitionSupported } from '$lib/utils/speech';
  import { speak, stopSpeaking } from '$lib/utils/speech-synthesis';
  import { assessExplanation } from '$lib/api/study';

  interface Props {
    nodeId: number;
    nodeName: string;
    subject: string;
    onComplete: (success: boolean, energyReward: number) => void;
  }

  let { nodeId, nodeName, subject, onComplete }: Props = $props();

  type Phase = 'intro' | 'spirit_ask' | 'listening' | 'recognized' | 'spirit_followup' | 'listening2' | 'recognized2' | 'assessing' | 'result';

  let phase = $state<Phase>('intro');
  let transcript1 = $state('');
  let transcript2 = $state('');
  let interimText = $state('');
  let stopFn: (() => void) | null = null;
  let assessing = $state(false);
  let assessmentResult = $state<any>(null);
  let error = $state('');

  // Translate Web Speech API errors to Chinese
  function translateSpeechError(err: string): string {
    const map: Record<string, string> = {
      'no-speech': '未检测到语音，请重试',
      'audio-capture': '未找到麦克风',
      'not-allowed': '麦克风权限被拒绝',
      'network': '网络错误，请检查网络',
      'aborted': '语音识别已取消',
    };
    return map[err] || err;
  }
  let spiritSpeaking = $state(false);
  let timerCountdown = $state(0);
  let timerInterval: ReturnType<typeof setInterval> | null = null;

  const supported = $derived(isSpeechRecognitionSupported);

  const questions = $derived.by(() => [
    `你能给小精灵讲讲什么是${nodeName}吗？`,
    `太棒了！那你能举个${nodeName}的例子吗？`
  ]);

  function startPhase() {
    phase = 'spirit_ask';
    spiritSpeaking = true;
    speak(questions[0], {
      lang: subject === 'chinese' ? 'zh-CN' : subject === 'english' ? 'en-US' : 'zh-CN',
      rate: 1.0, pitch: 1.3,
      onEnd: () => { spiritSpeaking = false; }
    });
  }

  function startListeningRound(round: 1 | 2) {
    phase = round === 1 ? 'listening' : 'listening2';
    interimText = '';
    error = '';
    timerCountdown = 30;
    startTimer();
    stopFn = startListening(
      subject === 'chinese' ? 'zh-CN' : subject === 'english' ? 'en-US' : 'zh-CN',
      (text, isFinal) => {
        interimText = text;
        if (isFinal) {
          if (round === 1) { transcript1 = text; phase = 'recognized'; }
          else { transcript2 = text; phase = 'recognized2'; }
          stopTimer();
        }
      },
      (err) => { error = translateSpeechError(err); stopTimer(); },
      () => { if (!interimText) stopTimer(); }
    );
    if (!stopFn) { stopTimer(); }
  }

  function startTimer() {
    stopTimer();
    timerInterval = setInterval(() => {
      timerCountdown--;
      if (timerCountdown <= 0) {
        stopTimer();
        if (stopFn) { stopFn(); stopFn = null; }
        if (phase === 'listening' && !transcript1) { transcript1 = interimText || '(无语音)'; phase = 'recognized'; }
        else if (phase === 'listening2' && !transcript2) { transcript2 = interimText || '（未识别到语音）'; phase = 'recognized2'; }
      }
    }, 1000);
  }

  function stopTimer() {
    if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
  }

  function stopAll() {
    if (stopFn) { stopFn(); stopFn = null; }
    stopSpeaking();
    stopTimer();
  }

  async function submitForAssessment() {
    assessing = true;
    phase = 'assessing';
    const fullText = transcript1 + ' ' + transcript2;
    try {
      assessmentResult = await assessExplanation(nodeId, fullText);
      phase = 'result';
      const msg = assessmentResult.score >= 80
        ? "哇！你讲解得太棒了！你是真正的小老师！"
        : assessmentResult.score >= 50 ? "做得好！你涵盖了关键知识点！" : "不错！让我们一起复习吧！";
      speak(msg, { lang: 'zh-CN', rate: 1.0, pitch: 1.4 });
    } catch (e: any) {
      error = e.message || '评估失败';
      phase = 'result';
    } finally { assessing = false; }
  }

  function handleSpiritFollowup() {
    phase = 'spirit_followup';
    spiritSpeaking = true;
    speak(questions[1], {
      lang: subject === 'chinese' ? 'zh-CN' : subject === 'english' ? 'en-US' : 'zh-CN',
      rate: 1.0, pitch: 1.3,
      onEnd: () => { spiritSpeaking = false; }
    });
  }

  function handleComplete() {
    stopAll();
    onComplete(assessmentResult?.score >= 50, assessmentResult?.energyReward || 5);
  }

  function finishListening(round: 1 | 2) {
    stopAll();
    if (round === 1) { if (interimText) transcript1 = interimText; phase = 'recognized'; }
    else { if (interimText) transcript2 = interimText; phase = 'recognized2'; }
  }

  onDestroy(() => { stopAll(); });
</script>

<div class="little-teacher bg-gradient-to-b from-indigo-50 via-purple-50 to-pink-50 rounded-2xl shadow-xl p-5 border-2 border-purple-300 relative overflow-hidden">
  <div class="absolute top-2 right-4 text-yellow-300 text-xl animate-pulse">&#9733;</div>
  <div class="absolute top-6 right-10 text-pink-300 text-sm animate-pulse" style="animation-delay:0.5s">&#9733;</div>
  <div class="absolute bottom-4 left-4 text-blue-300 text-sm animate-pulse" style="animation-delay:1s">&#9733;</div>

  {#if phase === 'intro'}
    <div class="text-center py-4">
      <div class="text-6xl mb-4 animate-bounce">&#127891;</div>
      <h3 class="text-xl font-bold text-purple-800 mb-2">小老师挑战！</h3>
      <p class="text-sm text-gray-600 mb-2">
        现在你是小老师！你能教小精灵关于 <strong>{nodeName}</strong> 的知识吗？
      </p>
      <p class="text-xs text-purple-500 mb-4">用语音来讲解吧！</p>
      <button onclick={startPhase}
        class="px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white text-lg font-bold rounded-2xl hover:from-purple-600 hover:to-pink-600 transition active:scale-95 shadow-lg animate-pulse">
        &#127908; 开始教学！
      </button>
    </div>

  {:else if phase === 'spirit_ask'}
    <div class="text-center py-4">
      <div class="relative inline-block mb-4">
        <div class="text-5xl {spiritSpeaking ? 'animate-bounce' : ''}">&#129498;</div>
        {#if spiritSpeaking}
          <div class="absolute -bottom-1 left-1/2 -translate-x-1/2 flex gap-0.5">
            <div class="w-1.5 h-3 bg-purple-400 rounded-full animate-pulse"></div>
            <div class="w-1.5 h-4 bg-pink-400 rounded-full animate-pulse" style="animation-delay:0.1s"></div>
            <div class="w-1.5 h-2 bg-purple-400 rounded-full animate-pulse" style="animation-delay:0.2s"></div>
          </div>
        {/if}
      </div>
      <div class="bg-white rounded-2xl p-4 mb-4 shadow-sm border border-purple-200 relative">
        <div class="absolute -top-2 left-1/2 -translate-x-1/2 w-4 h-4 bg-white border-l border-t border-purple-200 rotate-45"></div>
        <p class="text-base font-medium text-gray-800">{questions[0]}</p>
      </div>
      <button onclick={() => startListeningRound(1)}
        class="px-6 py-3 bg-gradient-to-r from-green-400 to-emerald-500 text-white font-bold rounded-xl hover:from-green-500 hover:to-emerald-600 transition active:scale-95 shadow-md">
        &#127908; 我准备好回答了！
      </button>
    </div>

  {:else if phase === 'listening' || phase === 'listening2'}
    <div class="text-center py-4">
      <p class="text-sm text-purple-600 mb-3 font-medium">&#127908; 正在聆听... ({timerCountdown}秒)</p>
      <div class="relative inline-block mb-4">
        <div class="w-28 h-28 rounded-full {phase === 'listening' ? 'bg-gradient-to-br from-purple-400 to-pink-500' : 'bg-gradient-to-br from-green-400 to-teal-500'} flex items-center justify-center shadow-xl">
          <span class="text-5xl">&#127908;</span>
        </div>
        <div class="absolute inset-0 rounded-full border-4 border-purple-300 animate-ping opacity-30"></div>
        <div class="absolute -inset-3 rounded-full border-2 border-pink-300 animate-ping opacity-20" style="animation-delay:0.5s"></div>
      </div>
      {#if interimText}
        <div class="bg-white/80 rounded-xl p-3 mb-3 mx-auto max-w-sm">
          <p class="text-sm text-gray-600 italic">"{interimText}"</p>
        </div>
      {/if}
      {#if !supported}
        <div class="mt-3">
          <p class="text-xs text-gray-500 mb-2">语音功能不可用，请输入你的答案：</p>
          {#if phase === 'listening'}
            <input type="text" bind:value={transcript1}
              class="w-full px-4 py-2 border-2 border-purple-300 rounded-xl text-sm focus:border-purple-500 outline-none"
              placeholder="在此输入..." />
          {:else}
            <input type="text" bind:value={transcript2}
              class="w-full px-4 py-2 border-2 border-purple-300 rounded-xl text-sm focus:border-purple-500 outline-none"
              placeholder="在此输入..." />
          {/if}
          <button onclick={() => { if (phase === 'listening') { phase = 'recognized'; } else { phase = 'recognized2'; } }}
            class="mt-2 px-4 py-2 bg-purple-500 text-white rounded-xl text-sm">提交</button>
        </div>
      {/if}
      <button onclick={() => finishListening(phase === 'listening' ? 1 : 2)}
        class="mt-3 px-4 py-2 bg-gray-200 text-gray-600 rounded-xl text-sm hover:bg-gray-300 transition">
        说完啦
      </button>
    </div>

  {:else if phase === 'recognized'}
    <div class="text-center py-4">
      <div class="text-4xl mb-3">&#10024;</div>
      <p class="text-sm text-gray-500 mb-2">你说的是：</p>
      <div class="bg-white rounded-xl p-4 mb-4 shadow-sm border border-green-200">
        <p class="text-base text-gray-800">"{transcript1 || '(空)'}"</p>
      </div>
      {#if !transcript1}
        <button onclick={() => startListeningRound(1)}
          class="px-4 py-2 bg-orange-400 text-white rounded-xl text-sm mr-2 hover:bg-orange-500 transition">&#128260; 再试一次</button>
      {/if}
      <button onclick={handleSpiritFollowup}
        class="px-6 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white font-bold rounded-xl hover:from-purple-600 hover:to-pink-600 transition active:scale-95 shadow-md">
        继续 &#10148;
      </button>
    </div>

  {:else if phase === 'spirit_followup'}
    <div class="text-center py-4">
      <div class="relative inline-block mb-4">
        <div class="text-5xl {spiritSpeaking ? 'animate-bounce' : ''}">&#129498;</div>
        {#if spiritSpeaking}
          <div class="absolute -bottom-1 left-1/2 -translate-x-1/2 flex gap-0.5">
            <div class="w-1.5 h-3 bg-purple-400 rounded-full animate-pulse"></div>
            <div class="w-1.5 h-4 bg-pink-400 rounded-full animate-pulse" style="animation-delay:0.1s"></div>
            <div class="w-1.5 h-2 bg-purple-400 rounded-full animate-pulse" style="animation-delay:0.2s"></div>
          </div>
        {/if}
      </div>
      <div class="bg-white rounded-2xl p-4 mb-4 shadow-sm border border-purple-200 relative">
        <div class="absolute -top-2 left-1/2 -translate-x-1/2 w-4 h-4 bg-white border-l border-t border-purple-200 rotate-45"></div>
        <p class="text-base font-medium text-gray-800">{questions[1]}</p>
      </div>
      <button onclick={() => startListeningRound(2)}
        class="px-6 py-3 bg-gradient-to-r from-green-400 to-emerald-500 text-white font-bold rounded-xl hover:from-green-500 hover:to-emerald-600 transition active:scale-95 shadow-md">
        &#127908; 让我来讲解！
      </button>
    </div>

  {:else if phase === 'recognized2'}
    <div class="text-center py-4">
      <div class="text-4xl mb-3">&#10024;</div>
      <p class="text-sm text-gray-500 mb-2">你还说了：</p>
      <div class="bg-white rounded-xl p-4 mb-4 shadow-sm border border-green-200">
        <p class="text-base text-gray-800">"{transcript2 || "（未识别到语音）"}"</p>
      </div>
      {#if !transcript2}
        <button onclick={() => startListeningRound(2)}
          class="px-4 py-2 bg-orange-400 text-white rounded-xl text-sm mr-2 hover:bg-orange-500 transition">&#128260; 再试一次</button>
      {/if}
      <button onclick={submitForAssessment} disabled={assessing}
        class="px-6 py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white font-bold rounded-xl hover:from-amber-500 hover:to-orange-600 transition active:scale-95 shadow-md disabled:opacity-50">
        {assessing ? "评估中..." : "✨ 查看我的得分！"}
      </button>
    </div>

  {:else if phase === 'assessing'}
    <div class="text-center py-8">
      <div class="text-5xl mb-4 animate-spin" style="animation-duration:2s">&#128302;</div>
      <p class="text-lg font-bold text-purple-700">正在评估你的讲解...</p>
      <div class="mt-4 flex justify-center gap-1">
        {#each Array(5) as _, i}
          <div class="w-2 h-8 bg-purple-400 rounded-full animate-pulse" style="animation-delay:{i * 0.15}s"></div>
        {/each}
      </div>
    </div>

  {:else if phase === 'result' && assessmentResult}
    <div class="text-center py-4">
      <div class="text-6xl mb-3 {assessmentResult.score >= 80 ? 'animate-bounce' : ''}">
        {assessmentResult.score >= 80 ? '🏆' : assessmentResult.score >= 50 ? '✨' : '💪'}
      </div>
      <h3 class="text-xl font-bold text-purple-800 mb-2">
        {assessmentResult.score >= 80 ? '太棒了，小老师！' : assessmentResult.score >= 50 ? '讲解得很好！' : '继续加油！'}
      </h3>
      <div class="bg-white rounded-xl p-4 mb-4 shadow-sm border border-purple-200">
        <div class="text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-500 to-pink-500 mb-2">
          {assessmentResult.score} / 100
        </div>
        <p class="text-sm text-gray-600 mb-3">{assessmentResult.encouragement}</p>
        {#if assessmentResult.foundKeywords?.length > 0}
          <div class="mb-2">
            <p class="text-xs text-green-600 font-medium">已涉及的关键概念：</p>
            <div class="flex flex-wrap gap-1 mt-1 justify-center">
              {#each assessmentResult.foundKeywords as kw}
                <span class="px-2 py-0.5 bg-green-100 text-green-700 rounded-full text-xs">&#10003; {kw}</span>
              {/each}
            </div>
          </div>
        {/if}
        {#if assessmentResult.missingKeywords?.length > 0}
          <div>
            <p class="text-xs text-orange-600 font-medium">还可以提到：</p>
            <div class="flex flex-wrap gap-1 mt-1 justify-center">
              {#each assessmentResult.missingKeywords as kw}
                <span class="px-2 py-0.5 bg-orange-100 text-orange-700 rounded-full text-xs">{kw}</span>
              {/each}
            </div>
          </div>
        {/if}
      </div>
      <div class="bg-gradient-to-r from-amber-100 to-yellow-100 rounded-xl p-3 mb-4 border border-amber-300">
        <p class="text-sm font-bold text-amber-700">&#9889; +{assessmentResult.energyReward} 能量获得！</p>
      </div>
      <button onclick={handleComplete}
        class="px-8 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white text-lg font-bold rounded-2xl hover:from-purple-600 hover:to-pink-600 transition active:scale-95 shadow-lg">
        &#127881; 继续
      </button>
    </div>
  {/if}

  {#if error}
    <div class="mt-3 bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">{translateSpeechError(error)}</div>
  {/if}
</div>