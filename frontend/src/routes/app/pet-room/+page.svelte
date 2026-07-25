<script lang="ts">
  import { onMount } from 'svelte';
  import { getPetRoom, placeItem, removeItem, updatePosition, changeTheme, getAvailableDecorations, type PetRoomData, type PlacedItem } from '$lib/api/pet-room';
  import { getEquippedAccessories, type AccessoryDTO } from '$lib/api/spirit';
  import { getAllThemes, defaultTheme } from '$lib/room/themes/registry';
  import PetRoomScene from '$lib/components/room/PetRoomScene.svelte';
  import DecorationPicker from '$lib/components/room/DecorationPicker.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';

  let room = $state<PetRoomData | null>(null);
  let decorations = $state<PlacedItem[]>([]);
  let spiritAccessories = $state<AccessoryDTO[]>([]);
  let loading = $state(true);
  let loadError = $state('');
  let editing = $state(false);
  let selectedItemId = $state<number | null>(null);
  let showThemePicker = $state(false);
  let showDecorationPicker = $state(false);
  let placementX = $state(200);
  let placementY = $state(220);

  // Preset positions for different furniture types (more natural layout)
  const presetPositions: Record<string, { x: number; y: number }[]> = {
    'deco_bed_small':    [{ x: 80, y: 210 }, { x: 320, y: 210 }],
    'deco_sofa':         [{ x: 200, y: 230 }, { x: 100, y: 230 }, { x: 300, y: 230 }],
    'deco_bookshelf':    [{ x: 50, y: 180 }, { x: 350, y: 180 }],
    'deco_lamp':         [{ x: 120, y: 200 }, { x: 280, y: 200 }],
    'deco_plant':        [{ x: 60, y: 220 }, { x: 340, y: 220 }, { x: 200, y: 240 }],
    'deco_rug_round':    [{ x: 200, y: 250 }],
    'deco_window':       [{ x: 200, y: 100 }],
    'deco_poster':       [{ x: 150, y: 80 }, { x: 250, y: 80 }],
    'deco_toy_ball':     [{ x: 180, y: 245 }, { x: 220, y: 245 }, { x: 150, y: 240 }],
    'deco_star_mobile':  [{ x: 200, y: 60 }],
    'deco_table':        [{ x: 200, y: 220 }],
    'deco_clock':        [{ x: 200, y: 70 }],
  };

  function getNaturalPosition(itemKey: string, existingFurniture: any[]): { x: number; y: number } {
    const presets = presetPositions[itemKey] || [{ x: 180 + Math.random() * 40, y: 210 + Math.random() * 30 }];
    for (const pos of presets) {
      const tooClose = existingFurniture.some(f => {
        const fx = f.x ?? 200;
        const fy = f.y ?? 220;
        const dist = Math.sqrt((fx - pos.x) ** 2 + (fy - pos.y) ** 2);
        return dist < 50;
      });
      if (!tooClose) return pos;
    }
    return { x: 100 + Math.random() * 200, y: 180 + Math.random() * 60 };
  }

  let themes = $derived(getAllThemes());

  onMount(async () => {
    await loadRoom();
    await loadDecorations();
    loading = false;
  });

  $effect(() => {
    if (room?.activeSpirit?.id) {
      getEquippedAccessories(room.activeSpirit.id)
        .then(a => spiritAccessories = a)
        .catch(() => spiritAccessories = []);
    }
  });

  async function loadRoom() {
    try { room = await getPetRoom(); } catch { room = null; }
  }

  async function loadDecorations() {
    try { decorations = await getAvailableDecorations(); } catch { decorations = []; }
  }

  function handleFurnitureClick(item: PlacedItem) {
    if (!editing) return;
    const id = item.userItemId ?? item.itemDefId;
    if (selectedItemId === id) {
      handleRemove(item);
    } else {
      selectedItemId = id;
    }
  }

  function handleAddDecoration() {
    showDecorationPicker = true;
    placementX = 180 + Math.random() * 40;
    placementY = 210 + Math.random() * 30;
  }

  async function handleSelectDecoration(item: PlacedItem) {
    showDecorationPicker = false;
    try {
      const pos = getNaturalPosition(item.itemKey, room?.furniture || []);
      room = await placeItem(item.userItemId ?? item.itemDefId, pos.x, pos.y);
      selectedItemId = null;
      await loadDecorations();
      toastStore.success(`已放置 ${item.name}`);
    } catch (e: any) { toastStore.error(e.message || '放置失败'); }
  }

  async function handleRemove(item: PlacedItem) {
    if (!room) return;
    const id = item.userItemId ?? item.itemDefId;
    try {
      room = await removeItem(id);
      selectedItemId = null;
      await loadDecorations();
      toastStore.success('已移除装饰品');
    } catch (e: any) { toastStore.error(e.message || '移除失败'); }
  }

  async function handleFurnitureDragEnd(item: PlacedItem, x: number, y: number) {
    const id = item.userItemId ?? item.itemDefId;
    try {
      room = await updatePosition(id, x, y);
    } catch { /* silent — position update is best-effort during drag */ }
  }

  function handleSpiritClick() {
    // The SpiritAvatar already shows a speech bubble on click via its internal click handler
    // This is a hook for future expansion (e.g. petting animation, mood boost)
  }

  async function handleChangeTheme(themeKey: string) {
    try {
      room = await changeTheme(themeKey);
      showThemePicker = false;
      toastStore.success('主题已切换');
    } catch (e: any) { toastStore.error(e.message || '切换失败'); }
  }
</script>

<svelte:head>
  <title>精灵小屋 - Pet Grow Up</title>
</svelte:head>

<div class="max-w-2xl mx-auto animate-slide-up">
  <div class="bg-white rounded-2xl shadow-sm p-6 border border-gray-100">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{room?.themeIcon || '🏠'} 精灵小屋</h1>
        <p class="text-gray-500 text-sm mt-1">
          {editing ? '点击家具选中后可移除，点"+"添加新装饰' : room?.themeName || '温馨小屋'}
        </p>
      </div>
      <div class="flex gap-2">
        <button onclick={() => showThemePicker = !showThemePicker}
                class="px-3 py-2 rounded-lg text-sm font-medium bg-purple-100 text-purple-700 transition">
          🎨 主题
        </button>
        <button onclick={() => { editing = !editing; selectedItemId = null; }}
                class="px-4 py-2 rounded-lg text-sm font-medium transition
                  {editing ? 'bg-green-100 text-green-700' : 'bg-indigo-100 text-indigo-700'}">
          {editing ? '✅ 完成' : '🔧 编辑'}
        </button>
      </div>
    </div>

    <!-- Theme picker -->
    {#if showThemePicker}
      <div class="mb-4 p-3 bg-purple-50 rounded-xl">
        <p class="text-sm text-gray-600 mb-2">选择房间主题</p>
        <div class="grid grid-cols-3 gap-2">
          {#each themes as t}
            <button onclick={() => handleChangeTheme(t.key)}
                    class="p-2 rounded-lg text-sm text-center transition
                      {(room?.roomStyle || defaultTheme.key) === t.key ? 'bg-purple-200 ring-2 ring-purple-400' : 'bg-white hover:bg-purple-100'}">
              <span class="text-xl">{t.icon}</span>
              <span class="block text-xs mt-1">{t.name}</span>
            </button>
          {/each}
        </div>
      </div>
    {/if}

    {#if loading}
      <div class="text-center text-gray-400 py-12">加载中...</div>
    {:else if room}
      <PetRoomScene {room} {editing} {selectedItemId}
        accessories={spiritAccessories}
        onfurnitureclick={handleFurnitureClick}
        onfurnituredragend={handleFurnitureDragEnd}
        onspiritclick={handleSpiritClick} />

      {#if editing}
        <div class="mt-3 text-center">
          <button onclick={handleAddDecoration}
                  class="px-4 py-2 rounded-lg text-sm font-medium bg-indigo-500 text-white hover:bg-indigo-600 transition">
            ➕ 添加装饰品
          </button>
          {#if selectedItemId}
            <span class="text-xs text-gray-400 ml-2">已选中家具，再次点击可移除</span>
          {/if}
        </div>
      {/if}

      {#if room.activeSpirit}
        <div class="mt-4 text-center">
          <p class="text-sm text-gray-500">
            {room.activeSpirit.nickname} · Lv.{room.activeSpirit.currentEvolutionStage}
          </p>
        </div>
      {/if}
    {:else}
      <div class="text-center text-gray-400 py-12">
        <p>还没有精灵？</p>
        <a href="/app/spirit/choose" class="text-indigo-500 hover:text-indigo-600">去选择一只精灵吧 →</a>
      </div>
    {/if}
  </div>

  <!-- Decoration picker modal -->
  <DecorationPicker
    items={decorations}
    show={showDecorationPicker}
    onselect={handleSelectDecoration}
    onclose={() => showDecorationPicker = false}
  />
</div>
