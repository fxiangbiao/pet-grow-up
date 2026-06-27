<script lang="ts">
  import { goto } from '$app/navigation';

  const subjects = [
    { key: 'chinese', name: '诗词大陆', emoji: '📜', desc: '探索古诗词的韵味', color: 'from-amber-400 to-orange-500' },
    { key: 'math', name: '智慧王国', emoji: '🔢', desc: '挑战数学的奥秘', color: 'from-blue-400 to-cyan-500' },
    { key: 'english', name: '魔法学院', emoji: '🔤', desc: '掌握英语的魔力', color: 'from-purple-400 to-pink-500' }
  ];
</script>

<svelte:head>
  <title>选择学科 - Pet Grow Up</title>
</svelte:head>

<div class="animate-slide-up">
  <h1 class="text-2xl font-bold text-gray-800 mb-2">选择学科世界</h1>
  <p class="text-gray-500 mb-8">进入一个学科世界，开始你的学习探险！</p>

  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
    {#each subjects as subject}
      <button
        onclick={() => goto(`/app/study/${subject.key}`)}
        class="rounded-2xl overflow-hidden shadow-sm hover:shadow-lg transition-all hover:-translate-y-1"
      >
        <div class="bg-gradient-to-br {subject.color} p-8 text-center text-white">
          <div class="text-6xl mb-3">{subject.emoji}</div>
          <h2 class="text-2xl font-bold">{subject.name}</h2>
          <p class="text-white/80 mt-2">{subject.desc}</p>
        </div>
        <div class="bg-white p-4 text-center text-sm text-gray-500">
          点击进入探险 →
        </div>
      </button>
    {/each}
  </div>
</div>
