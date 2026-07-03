<script lang="ts">
  // Full-width greeting banner shown when returning to the app after a break.
  // Different personalities have different greeting styles.

  import { onMount } from 'svelte';
  import SpiritAvatar from './SpiritAvatar.svelte';
  import SpiritSpeech from './SpiritSpeech.svelte';
  import type { SpiritSpecies } from '$lib/types/api';

  let {
    species,
    personality = 'cheerful',
    nickname = '星灵',
    dormancyLevel = 0,
    onDismiss = () => {}
  }: {
    species: SpiritSpecies | null;
    personality?: 'cheerful' | 'gentle' | 'tsundere' | 'brave';
    nickname?: string;
    dormancyLevel?: number;
    onDismiss?: () => void;
  } = $props();

  let visible = $state(true);
  let mood = $state<'greeting' | 'sleeping'>('greeting');

  $effect(() => {
    if (dormancyLevel >= 2) {
      mood = 'sleeping';
    } else {
      mood = 'greeting';
    }
  });

  const greetings: Record<string, Record<string, string[]>> = {
    cheerful: {
      normal: ['你终于来啦！今天学什么？', '等你好久啦～冲冲冲！', '耶！又见面啦！'],
      dim: ['你昨天没来...想你了！', '我等了一天一夜！快开始吧！'],
      sleeping: ['你终于来了！我睡了好久...', 'Zzz...啊！你回来了！我刚在梦里学数学...']
    },
    gentle: {
      normal: ['又见到你了，好开心', '今天也想和你一起学习呢', '你来了，真好'],
      dim: ['昨天很忙吗？没关系的...', '我等了你好久呢，不过没关系'],
      sleeping: ['你回来了...我做了个好长的梦', '梦到你来找我了，是真的呢']
    },
    tsundere: {
      normal: ['哼！才不是专门等你的...', '你、你总算来了！', '迟到了！...不过原谅你了'],
      dim: ['昨天为什么不来看我！...我才没有担心', '一整天都没来，笨蛋！'],
      sleeping: ['哼！知道回来了？我都睡了三天了！', '笨蛋笨蛋！你知道我睡了多久吗！']
    },
    brave: {
      normal: ['等你等得我都热身三遍了！', '战友来了！今天征服哪一科？', '好！全员集合！出发！'],
      dim: ['昨天缺勤一天！今天补上！', '报告！等你24小时了！'],
      sleeping: ['三天了！我还以为任务失败了！', '终于归队了！快开始紧急训练！']
    }
  };

  function getGreeting(): string {
    const pool = greetings[personality] || greetings.cheerful;
    let category: string[];
    if (dormancyLevel >= 2) category = pool.sleeping;
    else if (dormancyLevel >= 1) category = pool.dim;
    else category = pool.normal;
    return category[Math.floor(Math.random() * category.length)];
  }

  let greetingText = $state('');
  let dismissed = $state(false);

  onMount(() => {
    greetingText = getGreeting();
    // Auto-dismiss after 4.5s
    const timer = setTimeout(() => { dismiss(); }, 4500);
    return () => clearTimeout(timer);
  });

  function dismiss() {
    if (dismissed) return;
    dismissed = true;
    visible = false;
    setTimeout(() => onDismiss(), 300);
  }
</script>

{#if visible}
  <div class="relative overflow-hidden rounded-2xl mb-6 transition-all duration-300"
    class:opacity-0={dismissed}
    class:scale-95={dismissed}
    style="background: radial-gradient(ellipse at 30% 50%, rgba(99,102,241,0.15) 0%, rgba(15,13,31,0.95) 60%, #020617 100%);">
    <button
      onclick={dismiss}
      class="absolute top-3 right-3 z-10 w-7 h-7 rounded-full bg-white/10 text-white/60 hover:bg-white/20 hover:text-white flex items-center justify-center text-sm transition"
    >✕</button>

    <div class="flex items-center gap-4 px-5 py-4">
      <!-- Spirit avatar with greeting mood -->
      <div class="flex-shrink-0">
        {#if species}
          <SpiritAvatar {species} evolutionStage={1} size="sm" {mood} {personality} showSpeechBubble={false} />
        {:else}
          <div class="text-4xl animate-bounce-in">✨</div>
        {/if}
      </div>

      <!-- Greeting text -->
      <div class="flex-1 min-w-0">
        <p class="text-white text-sm font-semibold mb-1">
          {#if dormancyLevel >= 2}
            <span class="text-indigo-300">💤 {nickname} 刚睡醒</span>
          {:else if dormancyLevel >= 1}
            <span class="text-amber-300">😔 {nickname} 想你了</span>
          {:else}
            <span class="text-emerald-300">👋 {nickname} 来啦！</span>
          {/if}
        </p>
        <SpiritSpeech quote={greetingText} {personality} typewriter={true} typewriterSpeed={35} />
      </div>
    </div>

    <!-- Dormancy progress indicator -->
    {#if dormancyLevel >= 1}
      <div class="px-5 pb-3">
        <div class="flex items-center gap-2 text-xs text-indigo-300/70">
          <span>{dormancyLevel >= 2 ? '🔮 完成一次学习来唤醒星灵' : '⭐ 快来学习让星灵恢复活力'}</span>
        </div>
      </div>
    {/if}
  </div>
{/if}
