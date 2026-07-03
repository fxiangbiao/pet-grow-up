<script lang="ts">
  import { getSpiritDetail, feedSpirit, evolveSpirit, getEquippedAccessories, equipAccessory, unequipAccessory, type AccessoryDTO } from '$lib/api/spirit';
  import { getInventory } from '$lib/api/shop';
  import type { UserItem } from '$lib/types/api';
  import { page } from '$app/stores';
  import type { SpiritDTO } from '$lib/types/api';
  import PersonalityRadar from '$lib/components/spirit/PersonalityRadar.svelte';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import CelebrationOverlay from '$lib/components/feedback/CelebrationOverlay.svelte';
  import { authStore } from '$lib/stores/auth.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';
  import ItemSelector from '$lib/components/shop/ItemSelector.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  let spirit = $state<SpiritDTO | null>(null);
  let loading = $state(true);
  let loadError = $state('');
  let feedAmount = $state(50);
  let feeding = $state(false);
  let evolving = $state(false);
  let message = $state('');
  let messageType = $state<'success' | 'error' | ''>('');
  let showCelebration = $state(false);
  let feedHearts = $state<Array<{ id: number; x: number; delay: number }>>([]);
  let prevHappiness = $state(0);
  let prevEnergy = $state(0);
  let showHappinessChange = $state(0);
  let showEnergyChange = $state(0);
  let showChangeFlags = $state({ happiness: false, energy: false });
  let accessories = $state<AccessoryDTO[]>([]);
  let inventory = $state<UserItem[]>([]);

  let heartIdCounter = $state(0);

  $effect(() => {
    const id = Number($page.params.id);
    if (id) {
      getSpiritDetail(id).then(s => {
        spirit = s;
        prevHappiness = s.happiness;
        prevEnergy = s.energy;
        loading = false;
        // Load accessories and inventory
        getEquippedAccessories(id).then(a => accessories = a).catch(() => {});
        getInventory().then(inv => inventory = inv).catch(() => {});
      }).catch(() => {
        loading = false;
        loadError = '无法加载精灵详情，请检查网络或重新登录';
      });
    }
  });

  async function handleEquip(slot: string, itemDefId: number) {
    if (!spirit) return;
    try {
      const updated = await equipAccessory(spirit.id, slot, itemDefId);
      accessories = updated;
      toastStore.success('装备成功！');
    } catch (e: any) { toastStore.error(e.message || '装备失败'); }
  }

  async function handleUnequip(slot: string) {
    if (!spirit) return;
    try {
      const updated = await unequipAccessory(spirit.id, slot);
      accessories = updated;
      toastStore.success('已卸下');
    } catch (e: any) { toastStore.error(e.message || '卸下失败'); }
  }

  const accBySlot = $derived.by(() => {
    const map: Record<string, AccessoryDTO> = {};
    for (const a of accessories) map[a.slot] = a;
    return map;
  });

  const accessoryItems = $derived(inventory.filter(i => i.itemDef?.category === 'ACCESSORY'));

  const slots = [
    { key: 'head', label: '头部', icon: '🎩' },
    { key: 'neck', label: '颈部', icon: '🧣' },
    { key: 'eyes', label: '眼部', icon: '👓' },
    { key: 'effect', label: '特效', icon: '✨' },
  ];

  function triggerHearts() {
    const newHearts = Array.from({ length: 8 }, (_, i) => ({
      id: heartIdCounter + i,
      x: 20 + Math.random() * 60,
      delay: Math.random() * 0.3
    }));
    heartIdCounter += 8;
    feedHearts = [...feedHearts, ...newHearts];
    setTimeout(() => {
      feedHearts = [];
    }, 2500);
  }

  async function handleFeed() {
    if (!spirit) return;
    feeding = true;
    message = '';
    messageType = '';
    try {
      const oldHappiness = spirit.happiness;
      const oldEnergy = spirit.energy;
      spirit = await feedSpirit(spirit.id, feedAmount);
      showHappinessChange = spirit.happiness - oldHappiness;
      showEnergyChange = spirit.energy - oldEnergy;
      showChangeFlags = { happiness: true, energy: true };
      soundManager.playFeed();
      message = `好满足！快乐度 +${showHappinessChange}，精力 +${showEnergyChange}`;
      messageType = 'success';
      triggerHearts();
      authStore.refreshProfile();
      setTimeout(() => { showChangeFlags = { happiness: false, energy: false }; }, 2000);
    } catch (e: any) {
      const msg = e.message || '';
      if (msg.includes('Insufficient') || msg.includes('energy')) {
        toastStore.error('能量不足，无法喂食！去完成学习任务获取能量吧 ⚡');
      } else if (msg.includes('Not your spirit')) {
        toastStore.error('这不是你的精灵！');
      } else {
        toastStore.error(msg || '喂食失败，请稍后重试');
      }
    } finally {
      feeding = false;
    }
  }

  async function handleEvolve() {
    if (!spirit) return;
    evolving = true;
    message = '';
    messageType = '';
    try {
      spirit = await evolveSpirit(spirit.id);
      message = `✨ ${spirit.nickname} 进化成了 ${spirit.species.name}！`;
      messageType = 'success';
      showCelebration = true;
      soundManager.playEvolve();
      authStore.refreshProfile();
      setTimeout(() => { showCelebration = false; }, 3000);
    } catch (e: any) {
      const msg = e.message || '';
      if (msg.includes('Insufficient') || msg.includes('energy')) {
        toastStore.error('能量不足，无法进化！请积累更多能量 ⚡');
      } else if (msg.includes('cannot evolve')) {
        toastStore.error('这只精灵已经达到最高形态了！');
      } else {
        toastStore.error(msg || '进化失败，请稍后重试');
      }
    } finally {
      evolving = false;
    }
  }
</script>

<svelte:head>
  <title>精灵详情 - Pet Grow Up</title>
</svelte:head>

<div class="animate-slide-up max-w-2xl mx-auto">
  {#if loading}
    <div class="text-center text-gray-500 py-12">加载中...</div>
  {:else if loadError}
    <div class="max-w-md mx-auto text-center py-12">
      <div class="text-5xl mb-4">🔒</div>
      <p class="text-gray-500 mb-4">{loadError}</p>
      <a href="/login" class="inline-block px-6 py-3 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition">
        重新登录
      </a>
    </div>
  {:else if spirit}
    {#if showCelebration}
      <CelebrationOverlay />
    {/if}

    <!-- Feed hearts animation -->
    {#each feedHearts as heart (heart.id)}
      <div
        class="fixed pointer-events-none z-50 text-2xl animate-heart-float"
        style="left: {heart.x}%; bottom: 30%; animation-delay: {heart.delay}s;"
      >
        ❤️
      </div>
    {/each}

    <div class="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 relative">
      <!-- Spirit avatar section with sparkle effect on evolve -->
      <div class="text-center mb-6">
        <div class="inline-flex mb-2 transition-all duration-500" class:animate-bounce-in={showCelebration}>
          <SpiritAvatar species={spirit.species} evolutionStage={spirit.currentEvolutionStage} size="lg" {accessories} />
        </div>
        <h1 class="text-2xl font-bold text-gray-800">{spirit.nickname}</h1>
        <p class="text-gray-500">
          {#if showCelebration}
            <span class="text-purple-600 font-semibold animate-pulse">{spirit.species.name}</span>
          {:else}
            {spirit.species.name}
          {/if}
           · Lv.{spirit.currentEvolutionStage}
        </p>

        <!-- Sprint E: Equipment slots -->
        <div class="grid grid-cols-4 gap-2 mt-3 max-w-xs mx-auto">
          {#each slots as slot}
            <div class="text-center">
              <div class="text-xs text-gray-400 mb-1">{slot.icon} {slot.label}</div>
              {#if accBySlot[slot.key]}
                <button
                  onclick={() => handleUnequip(slot.key)}
                  class="w-full px-2 py-1.5 rounded-lg text-xs bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-red-50 hover:text-red-600 transition"
                  title={accBySlot[slot.key].name}>
                  {accBySlot[slot.key].iconUrl || '✨'}
                </button>
              {:else}
                <div class="relative group">
                  <div class="w-full px-2 py-1.5 rounded-lg text-xs bg-gray-100 text-gray-400 border border-dashed border-gray-300">
                    空
                  </div>
                  {#if accessoryItems.length > 0}
                    <div class="hidden group-hover:block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 bg-white border shadow-lg rounded-lg p-2 z-10 min-w-[120px]">
                      {#each accessoryItems.filter(i => !Object.values(accBySlot).some(a => a.itemKey === i.itemDef.itemKey)) as item}
                        <button
                          onclick={() => handleEquip(slot.key, item.itemDef.id)}
                          class="block w-full text-left px-2 py-1 text-xs hover:bg-indigo-50 rounded transition">
                          {item.itemDef.iconUrl || '✨'} {item.itemDef.name}
                        </button>
                      {/each}
                      {#if accessoryItems.filter(i => !Object.values(accBySlot).some(a => a.itemKey === i.itemDef.itemKey)).length === 0}
                        <span class="text-xs text-gray-400 px-2">没有可用的配饰</span>
                      {/if}
                    </div>
                  {/if}
                </div>
              {/if}
            </div>
          {/each}
        </div>
      </div>

      <!-- Status bars with animated transitions -->
      <div class="space-y-4 mb-6">
        <div>
          <div class="flex justify-between text-sm text-gray-600 mb-1">
            <span>亲密度</span><span>{spirit.affection}</span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
            <div
              class="bg-gradient-to-r from-pink-300 to-pink-400 h-3 rounded-full transition-all duration-1000 ease-out"
              style="width: {Math.min(spirit.affection, 100)}%"
            ></div>
          </div>
        </div>
        <div>
          <div class="flex justify-between text-sm text-gray-600 mb-1">
            <span>快乐度</span>
            <span class="transition-all duration-500">
              {spirit.happiness}%
              {#if showChangeFlags.happiness && showHappinessChange > 0}
                <span class="text-green-500 font-bold animate-bounce-in inline-block">+{showHappinessChange}</span>
              {/if}
            </span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
            <div
              class="bg-gradient-to-r from-yellow-300 to-yellow-400 h-3 rounded-full transition-all duration-1000 ease-out"
              style="width: {spirit.happiness}%"
            ></div>
          </div>
        </div>
        <div>
          <div class="flex justify-between text-sm text-gray-600 mb-1">
            <span>精力</span>
            <span class="transition-all duration-500">
              {spirit.energy}%
              {#if showChangeFlags.energy && showEnergyChange > 0}
                <span class="text-green-500 font-bold animate-bounce-in inline-block">+{showEnergyChange}</span>
              {/if}
            </span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
            <div
              class="bg-gradient-to-r from-green-300 to-green-400 h-3 rounded-full transition-all duration-1000 ease-out"
              style="width: {spirit.energy}%"
            ></div>
          </div>
        </div>
      </div>

      {#if spirit.personality}
        <div class="mb-6">
          <h3 class="text-sm font-semibold text-gray-600 mb-3 text-center">性格特质</h3>
          <PersonalityRadar personality={spirit.personality} size={220} />
        </div>
      {/if}

      <!-- Dynamic feedback message -->
      {#if message}
        <div
          class="text-center text-sm mb-4 p-3 rounded-xl transition-all duration-300 animate-slide-up"
          class:bg-green-50:text-green-700={messageType === 'success'}
          class:bg-red-50:text-red-600={messageType === 'error'}
          class:bg-indigo-50:text-indigo-600={messageType === ''}
        >
          {message}
        </div>
      {/if}

      <!-- Feed + Evolve controls -->
      <div class="flex flex-wrap gap-3 items-end">
        <div class="flex-1">
          <label for="feed-amount" class="block text-sm font-medium text-gray-600 mb-1.5">
            🍬 喂食能量
          </label>
          <div class="flex gap-2">
            <input id="feed-amount" type="number" bind:value={feedAmount} min={1} max={1000}
                   class="flex-1 px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-amber-300 focus:border-amber-400 outline-none transition" />
            <button onclick={handleFeed} disabled={feeding}
                    class="px-5 py-2.5 bg-gradient-to-r from-amber-400 to-orange-400 text-white rounded-lg text-sm font-semibold hover:from-amber-500 hover:to-orange-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-95 shadow-sm">
              {feeding ? '🍽️ 喂食中...' : '🍼 喂食'}
            </button>
          </div>
        </div>
        <button onclick={handleEvolve} disabled={evolving}
                class="px-5 py-2.5 bg-gradient-to-r from-purple-400 to-violet-500 text-white rounded-lg text-sm font-semibold hover:from-purple-500 hover:to-violet-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-95 shadow-sm">
          {evolving ? '✨ 进化中...' : '🌟 进化'}
        </button>
      </div>

      <!-- Item usage -->
      {#if spirit}
        <div class="mt-4">
          <ItemSelector spiritId={spirit.id}
            onItemUsed={(result) => {
              const s = spirit!;
              if (result.happinessChange) s.happiness = Math.min(100, (s.happiness || 0) + result.happinessChange);
              if (result.energyChange) s.energy = Math.min(100, (s.energy || 0) + result.energyChange);
              if (result.affectionChange) s.affection = (s.affection || 0) + result.affectionChange;
              showHappinessChange = result.happinessChange || 0;
              showEnergyChange = result.energyChange || 0;
              showChangeFlags = { happiness: result.happinessChange > 0, energy: result.energyChange > 0 };
              message = `使用 ${result.itemName} 成功！` + (
                result.affectionChange ? ` 亲密度 +${result.affectionChange}` :
                result.happinessChange ? ` 快乐度 +${result.happinessChange}` :
                result.energyChange ? ` 精力 +${result.energyChange}` : ''
              );
              messageType = 'success';
              setTimeout(() => { showChangeFlags = { happiness: false, energy: false }; }, 2000);
            }}
          />
        </div>
      {/if}
    </div>
  {/if}
</div>
