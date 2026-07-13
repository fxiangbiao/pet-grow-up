<script lang="ts">
  import type { WorldNode } from '$lib/api/study';

  interface Props {
    nodes: WorldNode[];
    subject: string;
    onNodeClick: (nodeId: number) => void;
  }

  let { nodes, subject, onNodeClick }: Props = $props();

  // Subject themes
  const themes: Record<string, {
    bg: string; trunk: string; leaf: string; leafLocked: string;
    leafCompleted: string; glow: string; icon: string; label: string;
  }> = {
    chinese: {
      bg: 'from-green-50 to-amber-50',
      trunk: '#8B6914',
      leaf: '#22c55e',
      leafLocked: '#d1d5db',
      leafCompleted: '#eab308',
      glow: '#fbbf24',
      icon: '🌿',
      label: '诗词树'
    },
    math: {
      bg: 'from-blue-50 to-indigo-50',
      trunk: '#6366f1',
      leaf: '#3b82f6',
      leafLocked: '#d1d5db',
      leafCompleted: '#f59e0b',
      glow: '#60a5fa',
      icon: '🏰',
      label: '数学城堡'
    },
    english: {
      bg: 'from-purple-50 to-pink-50',
      trunk: '#9333ea',
      leaf: '#a855f7',
      leafLocked: '#d1d5db',
      leafCompleted: '#f59e0b',
      glow: '#c084fc',
      icon: '🌸',
      label: '魔法森林'
    }
  };

  const theme = $derived(themes[subject] || themes.math);

  // Layout constants
  const NODE_RADIUS = 36;
  const CHILD_RADIUS = 28;
  const ROOT_SPACING = 200;
  const CHILD_SPACING = 90;
  const VERTICAL_GAP = 120;
  const PADDING = 60;

  // Calculate SVG dimensions based on tree structure
  const svgWidth = $derived(Math.max(
    nodes.length * ROOT_SPACING,
    ...nodes.map(n => Math.max(3, n.children?.length || 0) * CHILD_SPACING),
    400
  ));

  const maxChildren = $derived(Math.max(1, ...nodes.map(n => n.children?.length || 0)));
  const svgHeight = $derived(PADDING * 2 + NODE_RADIUS * 2 + (maxChildren > 0 ? VERTICAL_GAP + CHILD_RADIUS * 2 : 0));

  // Calculate positions for root nodes
  function getRootPositions() {
    const totalWidth = (nodes.length - 1) * ROOT_SPACING;
    const startX = (svgWidth - totalWidth) / 2;
    return nodes.map((_, i) => ({
      x: startX + i * ROOT_SPACING,
      y: PADDING + NODE_RADIUS
    }));
  }

  // Calculate positions for children of a root node
  function getChildPositions(rootX: number, rootY: number, childCount: number) {
    if (childCount === 0) return [];
    const totalWidth = (childCount - 1) * CHILD_SPACING;
    const startX = rootX - totalWidth / 2;
    const childY = rootY + VERTICAL_GAP;
    return Array.from({ length: childCount }, (_, i) => ({
      x: startX + i * CHILD_SPACING,
      y: childY
    }));
  }

  const rootPositions = $derived(getRootPositions());

  // Star rendering
  function renderStars(count: number): string {
    return '★'.repeat(count) + '☆'.repeat(3 - count);
  }
</script>

<div class="knowledge-tree rounded-2xl border-2 border-white/50 bg-gradient-to-b {theme.bg} p-4 overflow-x-auto">
  <!-- Title -->
  <div class="flex items-center gap-2 mb-3 px-2">
    <span class="text-2xl">{theme.icon}</span>
    <span class="font-bold text-gray-700">{theme.label}</span>
  </div>

  <!-- SVG Tree -->
  <svg
    width={svgWidth}
    height={svgHeight}
    viewBox="0 0 {svgWidth} {svgHeight}"
    class="mx-auto block"
    role="img"
    aria-label="{theme.label}知识树"
  >
    <!-- Connection lines: root to children -->
    {#each nodes as node, i}
      {#if node.children && node.children.length > 0}
        {@const childPositions = getChildPositions(rootPositions[i].x, rootPositions[i].y, node.children.length)}
        {#each childPositions as cp}
          <line
            x1={rootPositions[i].x}
            y1={rootPositions[i].y + NODE_RADIUS}
            x2={cp.x}
            y2={cp.y - CHILD_RADIUS}
            stroke={node.isCompleted ? theme.leafCompleted : (node.isUnlocked ? theme.trunk : '#e5e7eb')}
            stroke-width="3"
            stroke-dasharray={node.isUnlocked ? 'none' : '6,4'}
            opacity={node.isUnlocked ? 0.7 : 0.4}
          />
        {/each}
      {/if}
    {/each}

    <!-- Root nodes -->
    {#each nodes as node, i}
      {@const pos = rootPositions[i]}
      {@const isClickable = node.isUnlocked}

      <g
        class={isClickable ? 'cursor-pointer' : ''}
        on:click={isClickable ? () => onNodeClick(node.nodeId) : undefined}
        on:keydown={isClickable ? (e) => e.key === 'Enter' && onNodeClick(node.nodeId) : undefined}
        role={isClickable ? 'button' : undefined}
        tabindex={isClickable ? 0 : -1}
        aria-label="{node.name} {node.isCompleted ? '已完成' : node.isUnlocked ? '可探险' : '未解锁'}"
      >
        <!-- Glow effect for completed -->
        {#if node.isCompleted}
          <circle cx={pos.x} cy={pos.y} r={NODE_RADIUS + 8} fill={theme.glow} opacity="0.3">
            <animate attributeName="r" values="{NODE_RADIUS + 6};{NODE_RADIUS + 12};{NODE_RADIUS + 6}" dur="2s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.3;0.15;0.3" dur="2s" repeatCount="indefinite" />
          </circle>
        {/if}

        <!-- Pulse for unlocked (not completed) -->
        {#if node.isUnlocked && !node.isCompleted}
          <circle cx={pos.x} cy={pos.y} r={NODE_RADIUS + 4} fill={theme.leaf} opacity="0.2">
            <animate attributeName="r" values="{NODE_RADIUS + 2};{NODE_RADIUS + 10};{NODE_RADIUS + 2}" dur="1.5s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.3;0.1;0.3" dur="1.5s" repeatCount="indefinite" />
          </circle>
        {/if}

        <!-- Main circle -->
        <circle
          cx={pos.x}
          cy={pos.y}
          r={NODE_RADIUS}
          fill={node.isCompleted ? theme.leafCompleted : (node.isUnlocked ? theme.leaf : theme.leafLocked)}
          stroke={node.isCompleted ? '#d97706' : (node.isUnlocked ? theme.trunk : '#9ca3af')}
          stroke-width="3"
        />

        <!-- Lock icon for locked nodes -->
        {#if !node.isUnlocked}
          <text x={pos.x} y={pos.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="20" fill="#6b7280">🔒</text>
        {:else if node.isCompleted}
          <!-- Star rating for completed -->
          <text x={pos.x} y={pos.y - 4} text-anchor="middle" dominant-baseline="middle" font-size="14" fill="#92400e" font-weight="bold">
            {renderStars(node.starRating)}
          </text>
          <text x={pos.x} y={pos.y + 14} text-anchor="middle" font-size="11" fill="#92400e" font-weight="600">✓</text>
        {:else}
          <!-- Difficulty level for unlocked -->
          <text x={pos.x} y={pos.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="16" fill="white" font-weight="bold">
            Lv{node.difficulty}
          </text>
        {/if}

        <!-- Name label below -->
        <text x={pos.x} y={pos.y + NODE_RADIUS + 18} text-anchor="middle" font-size="13" fill={node.isUnlocked ? '#374151' : '#9ca3af'} font-weight="600">
          {node.name}
        </text>
      </g>
    {/each}

    <!-- Child nodes -->
    {#each nodes as node, i}
      {#if node.children && node.children.length > 0}
        {@const childPositions = getChildPositions(rootPositions[i].x, rootPositions[i].y, node.children.length)}
        {#each node.children as child, j}
          {@const cp = childPositions[j]}
          {@const childClickable = child.isUnlocked}

          <g
            class={childClickable ? 'cursor-pointer' : ''}
            on:click={childClickable ? () => onNodeClick(child.nodeId) : undefined}
            on:keydown={childClickable ? (e) => e.key === 'Enter' && onNodeClick(child.nodeId) : undefined}
            role={childClickable ? 'button' : undefined}
            tabindex={childClickable ? 0 : -1}
            aria-label="{child.name} {child.isCompleted ? '已完成' : child.isUnlocked ? '可探险' : '未解锁'}"
          >
            <!-- Glow for completed child -->
            {#if child.isCompleted}
              <circle cx={cp.x} cy={cp.y} r={CHILD_RADIUS + 6} fill={theme.glow} opacity="0.25">
                <animate attributeName="r" values="{CHILD_RADIUS + 4};{CHILD_RADIUS + 8};{CHILD_RADIUS + 4}" dur="2s" repeatCount="indefinite" />
              </circle>
            {/if}

            <!-- Pulse for unlocked child -->
            {#if child.isUnlocked && !child.isCompleted}
              <circle cx={cp.x} cy={cp.y} r={CHILD_RADIUS + 3} fill={theme.leaf} opacity="0.2">
                <animate attributeName="r" values="{CHILD_RADIUS + 2};{CHILD_RADIUS + 7};{CHILD_RADIUS + 2}" dur="1.5s" repeatCount="indefinite" />
              </circle>
            {/if}

            <!-- Main circle -->
            <circle
              cx={cp.x}
              cy={cp.y}
              r={CHILD_RADIUS}
              fill={child.isCompleted ? theme.leafCompleted : (child.isUnlocked ? theme.leaf : theme.leafLocked)}
              stroke={child.isCompleted ? '#d97706' : (child.isUnlocked ? theme.trunk : '#9ca3af')}
              stroke-width="2.5"
            />

            <!-- Content -->
            {#if !child.isUnlocked}
              <text x={cp.x} y={cp.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="16" fill="#6b7280">🔒</text>
            {:else if child.isCompleted}
              <text x={cp.x} y={cp.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="12" fill="#92400e" font-weight="bold">
                {renderStars(child.starRating)}
              </text>
            {:else}
              <text x={cp.x} y={cp.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="13" fill="white" font-weight="bold">
                Lv{child.difficulty}
              </text>
            {/if}

            <!-- Name label -->
            <text x={cp.x} y={cp.y + CHILD_RADIUS + 16} text-anchor="middle" font-size="12" fill={child.isUnlocked ? '#374151' : '#9ca3af'} font-weight="500">
              {child.name}
            </text>
          </g>
        {/each}
      {/if}
    {/each}
  </svg>

  <!-- Legend -->
  <div class="flex items-center justify-center gap-4 mt-2 text-xs text-gray-500">
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-yellow-400 inline-block"></span> 已完成
    </span>
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-blue-400 inline-block"></span> 可探险
    </span>
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-gray-300 inline-block"></span> 未解锁
    </span>
  </div>
</div>
