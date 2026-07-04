<script lang="ts">
  import type { PetRoomData, PlacedItem } from '$lib/api/pet-room';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { getTheme } from '$lib/room/themes/registry';
  import type { RoomTheme } from '$lib/room/themes/types';
  import { getFurnitureRenderer } from '$lib/room/furniture/registry';
  import type { FurnitureContext } from '$lib/room/furniture/types';
  import { pickNextState, getStateDuration, getBehaviorFrame, type BehaviorState } from '$lib/room/behavior';

  let {
    room,
    editing = false,
    selectedItemId = null as number | null,
    accessories = [] as { slot: string; iconUrl: string; name: string }[],
    onfurnitureclick,
    onfurnituredragend,
    onspiritclick,
  }: {
    room: PetRoomData;
    editing?: boolean;
    selectedItemId?: number | null;
    accessories?: { slot: string; iconUrl: string; name: string }[];
    onfurnitureclick?: (item: PlacedItem) => void;
    onfurnituredragend?: (item: PlacedItem, x: number, y: number) => void;
    onspiritclick?: () => void;
  } = $props();

  let theme = $derived(getTheme(room.roomStyle));
  let furniture = $derived(room.furniture || []);

  let floorY = 195;
  let backFurniture = $derived(furniture.filter(f => (f.y ?? 220) < floorY));
  let frontFurniture = $derived(furniture.filter(f => (f.y ?? 220) >= floorY));
  let sortedFront = $derived([...frontFurniture].sort((a, b) => (a.y ?? 220) - (b.y ?? 220)));

  // Interactive states (session-only, not persisted yet)
  let isNight = $state(false);
  let isLampOn = $state(true);
  let spiritSpinning = $state(false);

  // ── Spirit autonomous behavior ──
  let behaviorState = $state<BehaviorState>('idle_stand');
  let behaviorFrame = $derived(getBehaviorFrame(behaviorState));
  let behaviorTimer: ReturnType<typeof setTimeout> | null = null;

  function scheduleNextBehavior() {
    const happiness = room.activeSpirit?.happiness ?? 50;
    const next = pickNextState(behaviorState, furniture, happiness);
    const duration = getStateDuration(next);
    behaviorTimer = setTimeout(() => {
      behaviorState = next;
      scheduleNextBehavior();
    }, duration);
  }

  $effect(() => {
    // Start behavior loop when room loads
    scheduleNextBehavior();
    return () => { if (behaviorTimer) clearTimeout(behaviorTimer); };
  });

  let spiritMood = $derived.by((): 'idle' | 'happy' | 'excited' | 'hurt' | 'sleeping' | 'thinking' => {
    // Behavior mood takes precedence
    if (behaviorFrame.mood === 'sleeping') return 'sleeping';
    if (behaviorFrame.mood === 'thinking') return 'thinking';
    if (behaviorFrame.mood === 'excited') return 'excited';
    if (!room.activeSpirit) return 'idle';
    const s = room.activeSpirit;
    if (s.happiness >= 80) return 'excited';
    if (s.happiness >= 50) return 'happy';
    return 'idle';
  });

  let spiritLeft = $derived(behaviorFrame.position.left);
  let spiritBottom = $derived(behaviorFrame.position.bottom);
  let spiritLabel = $derived(behaviorFrame.label);

  // ── Drag state ──
  let dragItemId = $state<number | null>(null);
  let dragX = $state(0);
  let dragY = $state(0);
  // Live position of dragged item (for visual update during drag)
  let liveDragX = $state(0);
  let liveDragY = $state(0);
  let svgEl = $state<SVGSVGElement | null>(null);

  function svgCoords(e: PointerEvent): { x: number; y: number } {
    if (!svgEl) return { x: 0, y: 0 };
    const rect = svgEl.getBoundingClientRect();
    return {
      x: ((e.clientX - rect.left) / rect.width) * 400,
      y: ((e.clientY - rect.top) / rect.height) * 300,
    };
  }

  function handleDragStart(e: PointerEvent, item: PlacedItem) {
    if (!editing) return;
    const id = item.userItemId ?? item.itemDefId;
    dragItemId = id;
    const coords = svgCoords(e);
    dragX = coords.x - (item.x ?? 200);
    dragY = coords.y - (item.y ?? 220);
    liveDragX = item.x ?? 200;
    liveDragY = item.y ?? 220;
    (e.currentTarget as SVGElement).setPointerCapture(e.pointerId);
    e.stopPropagation();
  }

  function handleDragMove(e: PointerEvent) {
    if (dragItemId === null) return;
    const coords = svgCoords(e);
    liveDragX = Math.max(20, Math.min(380, coords.x - dragX));
    liveDragY = Math.max(30, Math.min(280, coords.y - dragY));
  }

  function handleDragEnd(e: PointerEvent) {
    if (dragItemId === null) return;
    const item = furniture.find(f => (f.userItemId ?? f.itemDefId) === dragItemId);
    if (item) {
      onfurnituredragend?.(item, Math.round(liveDragX), Math.round(liveDragY));
    }
    dragItemId = null;
    try { (e.currentTarget as SVGElement).releasePointerCapture(e.pointerId); } catch {}
  }

  function getDisplayX(item: PlacedItem): number {
    const id = item.userItemId ?? item.itemDefId;
    if (dragItemId === id) return liveDragX;
    return item.x ?? 200;
  }

  function getDisplayY(item: PlacedItem): number {
    const id = item.userItemId ?? item.itemDefId;
    if (dragItemId === id) return liveDragY;
    return item.y ?? 220;
  }

  function renderFurniture(item: PlacedItem): string {
    const renderer = getFurnitureRenderer(item.itemKey);
    const ctx: FurnitureContext = {
      x: getDisplayX(item),
      y: getDisplayY(item),
      scale: 1.0,
      floorY: 200,
    };
    if (!renderer) {
      return `<text x="${ctx.x}" y="${ctx.y}" font-size="24" text-anchor="middle" dominant-baseline="central">${item.iconUrl || '📦'}</text>`;
    }
    return renderer(ctx);
  }

  function renderParticles(t: RoomTheme): string {
    switch (t.ambientParticles) {
      case 'stars': {
        let s = '';
        for (let i = 0; i < 12; i++) {
          const px = 20 + ((i * 137 + 53) % 360);
          const py = 10 + ((i * 89 + 31) % 100);
          const r = 0.5 + (i % 3) * 0.5;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="#fbbf24" opacity="0.6">
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + (i % 3)}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'fireflies': {
        let s = '';
        for (let i = 0; i < 6; i++) {
          const px = 60 + i * 50;
          const py = 40 + (i % 3) * 50;
          s += `<circle cx="${px}" cy="${py}" r="2" fill="#fbbf24" opacity="0.7">
            <animate attributeName="cx" values="${px - 12};${px + 12};${px - 12}" dur="${3 + i}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + i * 0.3}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'petals': {
        let s = '';
        for (let i = 0; i < 8; i++) {
          const px = 30 + i * 45;
          const py = 20 + (i % 3) * 25;
          s += `<text x="${px}" y="${py}" font-size="6" fill="#f472b6" opacity="0.5">
            🌸
            <animate attributeName="y" values="${py};${py + 200}" dur="${5 + i}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.5;0.2;0" dur="${5 + i}s" repeatCount="indefinite"/>
          </text>`;
        }
        return s;
      }
      case 'sparkles': {
        let s = '';
        for (let i = 0; i < 10; i++) {
          const px = 30 + i * 36;
          const py = 15 + (i % 4) * 20;
          s += `<polygon points="${px},${py - 3} ${px + 2},${py} ${px},${py + 3} ${px - 2},${py}"
            fill="#a78bfa" opacity="0.6">
            <animate attributeName="opacity" values="0;0.8;0" dur="${1.5 + (i % 3) * 0.5}s" repeatCount="indefinite"/>
          </polygon>`;
        }
        return s;
      }
      case 'bubbles': {
        let s = '';
        for (let i = 0; i < 5; i++) {
          const px = 60 + i * 65;
          const py = 120 + i * 20;
          const r = 3 + i;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="none" stroke="#7dd3fc" stroke-width="0.8" opacity="0.4">
            <animate attributeName="cy" values="${py};${py - 160}" dur="${5 + i}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.4;0.1;0" dur="${5 + i}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      default: return '';
    }
  }

  // Wall style for night mode
  let wallOpacity = $derived(isNight ? 0.4 : 1);
  let glassColor = $derived(isNight ? '#0f172a' : theme.window.glassColor);
  let nightOverlay = $derived(isNight ? '<rect x="0" y="0" width="400" height="300" fill="#0f172a" opacity="0.5"/>' : '');
</script>

<div class="relative w-full max-w-lg mx-auto">
  <svg viewBox="0 0 400 300" class="w-full rounded-2xl shadow-lg border"
       style="border-color: {theme.colorScheme.primary}33;"
       bind:this={svgEl}
       onpointermove={handleDragMove}
       onpointerup={handleDragEnd}>

    <defs>
      <linearGradient id="wallGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.wall.gradient[0]}/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]}/>
      </linearGradient>
      <linearGradient id="floorGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.floor.color}/>
        <stop offset="100%" stop-color={theme.floor.plankColor}/>
      </linearGradient>
      <radialGradient id="lampGlow" cx="50%" cy="0%" r="60%">
        <stop offset="0%" stop-color={isLampOn ? theme.lamp.glowColor : '#4a5568'} stop-opacity={isLampOn ? 0.6 : 0.15}/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]} stop-opacity="0"/>
      </radialGradient>
    </defs>

    <!-- Wall -->
    <rect x="0" y="0" width="400" height="200" fill="url(#wallGrad)" opacity={wallOpacity}/>
    <ellipse cx="200" cy="0" rx="180" ry="100" fill="url(#lampGlow)"/>
    <!-- Night overlay -->
    {@html nightOverlay}

    <!-- Ambient particles -->
    {@html renderParticles(theme)}

    <!-- Window (clickable: toggle day/night) -->
    <g class="cursor-pointer" onclick={() => isNight = !isNight} role="button" tabindex="0"
       onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') isNight = !isNight; }}>
      {#if !furniture.some(f => f.itemKey === 'deco_window')}
        {#if theme.window.style === 'porthole'}
          <circle cx="200" cy="75" r="30" fill={glassColor} stroke={theme.window.frameColor} stroke-width="3"/>
          <circle cx="200" cy="75" r="27" fill="none" stroke={theme.window.frameColor} stroke-width="1" opacity="0.5"/>
        {:else if theme.window.style === 'round'}
          <circle cx="200" cy="75" r="35" fill={glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
          <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="1.5"/>
          <line x1="165" y1="75" x2="235" y2="75" stroke={theme.window.frameColor} stroke-width="1.5"/>
        {:else if theme.window.style === 'square'}
          <rect x="145" y="40" width="110" height="80" fill={glassColor} stroke={theme.window.frameColor} stroke-width="2.5" rx="2"/>
          <line x1="200" y1="40" x2="200" y2="120" stroke={theme.window.frameColor} stroke-width="1.5"/>
        {:else}
          <path d="M155,110 L155,50 Q155,40 165,40 L235,40 Q245,40 245,50 L245,110 Z"
                fill={glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
          <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="2"/>
        {/if}
        <!-- Day/night indicator -->
        <text x="200" y="90" text-anchor="middle" font-size="16" opacity="0.6">{isNight ? '🌙' : '☀️'}</text>
      {/if}
    </g>

    <!-- Ceiling lamp (clickable: toggle on/off) -->
    <g class="cursor-pointer" onclick={() => isLampOn = !isLampOn} role="button" tabindex="0"
       onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') isLampOn = !isLampOn; }}>
      {#if !furniture.some(f => f.itemKey === 'deco_lamp' || f.itemKey === 'deco_star_mobile')}
        {#if theme.lamp.style === 'lantern'}
          <line x1="200" y1="0" x2="200" y2="15" stroke="#713f12" stroke-width="1.5"/>
          <rect x="188" y="15" width="24" height="20" rx="3" fill={isLampOn ? '#dc2626' : '#6b7280'} opacity="0.8"/>
        {:else if theme.lamp.style === 'crystal'}
          <line x1="200" y1="0" x2="200" y2="12" stroke="#c4b5fd" stroke-width="1"/>
          <polygon points="188,12 212,12 206,22 194,22" fill={isLampOn ? '#a78bfa' : '#6b7280'} opacity="0.7"/>
          <polygon points="190,22 210,22 204,30 196,30" fill={isLampOn ? '#c4b5fd' : '#9ca3af'} opacity="0.5"/>
        {:else if theme.lamp.style === 'mushroom'}
          <line x1="200" y1="0" x2="200" y2="14" stroke="#78716c" stroke-width="1.5"/>
          <ellipse cx="200" cy="18" rx="14" ry="8" fill={isLampOn ? '#eab308' : '#6b7280'} opacity="0.7"/>
        {:else if theme.lamp.style === 'shell'}
          <line x1="200" y1="0" x2="200" y2="14" stroke="#475569" stroke-width="1"/>
          <path d="M185,14 Q200,8 215,14 Q200,28 185,14 Z" fill={isLampOn ? '#fbbf24' : '#6b7280'} opacity="0.5"/>
        {:else}
          <line x1="200" y1="0" x2="200" y2="20" stroke={isLampOn ? theme.lamp.bodyColor : '#6b7280'} stroke-width="1.5"/>
          <circle cx="200" cy="22" r="6" fill={isLampOn ? theme.lamp.glowColor : '#4a5568'} stroke={isLampOn ? theme.lamp.bodyColor : '#6b7280'} stroke-width="1"/>
        {/if}
      {/if}
    </g>

    <!-- Floor -->
    <rect x="0" y="200" width="400" height="100" fill="url(#floorGrad)"/>
    <line x1="0" y1="220" x2="400" y2="220" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <line x1="0" y1="245" x2="400" y2="245" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <rect x="0" y="197" width="400" height="3" fill={theme.floor.baseboardColor}/>

    <!-- Default rug (clickable: spirit spin dance) -->
    <g class="cursor-pointer" onclick={() => { spiritSpinning = true; setTimeout(() => spiritSpinning = false, 2000); }}
       role="button" tabindex="0"
       onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') { spiritSpinning = true; setTimeout(() => spiritSpinning = false, 2000); } }}>
      {#if !furniture.some(f => f.itemKey === 'deco_rug_round')}
        <ellipse cx="200" cy="248" rx="50" ry="12" fill={theme.defaultRug.color} opacity={theme.defaultRug.opacity}/>
      {/if}
    </g>

    <!-- Back furniture -->
    {#each backFurniture as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-grab active:cursor-grabbing' : ''}
         onpointerdown={(e: PointerEvent) => handleDragStart(e, item)}
         onclick={() => { if (!dragItemId) editing && onfurnitureclick?.(item); }}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId && dragItemId !== (item.userItemId ?? item.itemDefId)}
          <rect x={getDisplayX(item) - 22} y={getDisplayY(item) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Front furniture -->
    {#each sortedFront as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-grab active:cursor-grabbing' : ''}
         onpointerdown={(e: PointerEvent) => handleDragStart(e, item)}
         onclick={() => { if (!dragItemId) editing && onfurnitureclick?.(item); }}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId && dragItemId !== (item.userItemId ?? item.itemDefId)}
          <rect x={getDisplayX(item) - 22} y={getDisplayY(item) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Room label -->
    <text x="15" y="288" font-size="9" fill={theme.floor.plankColor} font-family="sans-serif">
      {theme.icon} {room.activeSpirit ? room.activeSpirit.nickname + '的小屋' : '温馨小屋'} · {theme.name}
    </text>
  </svg>

  <!-- Spirit overlaid — position driven by autonomous behavior state -->
  <div class="absolute pointer-events-auto cursor-pointer"
       style="left: {spiritLeft}; bottom: {spiritBottom}; transform: translateX(-50%){spiritSpinning ? ' rotate(360deg)' : ''};
         transition: left 2s ease-in-out, bottom 2s ease-in-out{spiritSpinning ? ', transform 0.6s ease-in-out' : ''};"
       onclick={onspiritclick}
       role={onspiritclick ? 'button' : undefined}
       tabindex={onspiritclick ? 0 : undefined}
       onkeydown={onspiritclick ? (e: KeyboardEvent) => { if (e.key === 'Enter') onspiritclick(); } : undefined}>
    {#if room.activeSpirit}
      <div class="relative">
        <SpiritAvatar
          species={room.activeSpirit.species}
          evolutionStage={room.activeSpirit.currentEvolutionStage}
          size="lg"
          mood={spiritMood}
          showSpeechBubble={true}
          {accessories}
        />
        <!-- Behavior label -->
        {#if spiritLabel}
          <div class="absolute -top-2 -right-2 text-sm animate-bounce-in pointer-events-none">{spiritLabel}</div>
        {/if}
      </div>
    {:else}
      <div class="w-16 h-16"></div>
    {/if}
  </div>
</div>
