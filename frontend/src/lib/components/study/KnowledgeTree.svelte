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
    trunk: string; branch: string; leaf: string; leafLocked: string;
    leafCompleted: string; glow: string; icon: string; label: string;
    bgFrom: string; bgTo: string;
  }> = {
    chinese: {
      trunk: '#6B4423', branch: '#8B6914', leaf: '#22c55e',
      leafLocked: '#d1d5db', leafCompleted: '#eab308', glow: '#fbbf24',
      icon: '', label: '诗词大陆', bgFrom: '#f0fdf4', bgTo: '#fefce8'
    },
    math: {
      trunk: '#4338ca', branch: '#6366f1', leaf: '#3b82f6',
      leafLocked: '#d1d5db', leafCompleted: '#f59e0b', glow: '#60a5fa',
      icon: '🏰', label: '数学城堡', bgFrom: '#eff6ff', bgTo: '#eef2ff'
    },
    english: {
      trunk: '#7e22ce', branch: '#9333ea', leaf: '#a855f7',
      leafLocked: '#d1d5db', leafCompleted: '#f59e0b', glow: '#c084fc',
      icon: '', label: '魔法森林', bgFrom: '#faf5ff', bgTo: '#fdf2f8'
    }
  };

  const theme = $derived(themes[subject] || themes.math);

  // Layout constants
  const NODE_R = 32;
  const PADDING_X = 60;
  const PADDING_Y = 40;
  const ROW_GAP = 100; // 行间距

  interface PathNode {
    node: WorldNode;
    x: number;
    y: number;
    index: number;
  }

  // 找到当前进度：第一个未完成的节点
  function findCurrentProgress(nodes: WorldNode[]): number {
    for (let i = 0; i < nodes.length; i++) {
      if (!nodes[i].isCompleted) return i;
    }
    return nodes.length;
  }

  // 蛇形路径布局
  function createSnakeLayout(nodes: WorldNode[], width: number, height: number): PathNode[] {
    if (nodes.length === 0) return [];

    // 计算每行能放几个节点
    const availableWidth = width - PADDING_X * 2;
    const nodesPerRow = Math.max(3, Math.floor(availableWidth / (NODE_R * 2 + 40)));
    
    // 计算行数
    const numRows = Math.ceil(nodes.length / nodesPerRow);
    const availableHeight = height - PADDING_Y * 2;
    const rowSpacing = Math.min(ROW_GAP, availableHeight / Math.max(1, numRows - 1));

    const result: PathNode[] = [];

    for (let i = 0; i < nodes.length; i++) {
      const row = Math.floor(i / nodesPerRow);
      const col = i % nodesPerRow;
      
      // 偶数行从左到右，奇数行从右到左（蛇形）
      const actualCol = row % 2 === 0 ? col : (nodesPerRow - 1 - col);
      
      // 计算实际节点数（最后一行可能不满）
      const nodesInRow = Math.min(nodesPerRow, nodes.length - row * nodesPerRow);
      const rowWidth = (nodesInRow - 1) * (NODE_R * 2 + 40);
      const startX = (width - rowWidth) / 2;
      
      const x = startX + actualCol * (NODE_R * 2 + 40);
      const y = PADDING_Y + row * rowSpacing;

      result.push({
        node: nodes[i],
        x,
        y,
        index: i
      });
    }

    return result;
  }

  // 容器尺寸
  const containerWidth = 800;
  const containerHeight = 600;

  // 生成布局
  const pathNodes = $derived(() => {
    if (nodes.length === 0) return [];
    return createSnakeLayout(nodes, containerWidth, containerHeight);
  });

  // 当前进度索引
  const currentProgress = $derived(() => findCurrentProgress(nodes));

  // 连线数据
  const edges = $derived(() => {
    const result: {
      from: PathNode;
      to: PathNode;
      type: 'completed' | 'current' | 'upcoming' | 'locked';
    }[] = [];

    const paths = pathNodes();
    if (paths.length < 2) return result;

    const progressIdx = currentProgress();

    for (let i = 0; i < paths.length - 1; i++) {
      const from = paths[i];
      const to = paths[i + 1];

      let type: 'completed' | 'current' | 'upcoming' | 'locked';

      if (i < progressIdx - 1) {
        type = 'completed';
      } else if (i === progressIdx - 1) {
        type = 'current';
      } else if (i === progressIdx) {
        type = 'upcoming';
      } else {
        type = 'locked';
      }

      result.push({ from, to, type });
    }

    return result;
  });

  function renderStars(count: number): string {
    return '★'.repeat(count) + '☆'.repeat(3 - count);
  }

  function getNodeStatus(node: WorldNode, index: number): 'completed' | 'current' | 'upcoming' | 'locked' {
    const progressIdx = currentProgress();

    if (index < progressIdx) return 'completed';
    if (index === progressIdx) return 'current';
    if (index === progressIdx + 1) return 'upcoming';
    return 'locked';
  }
</script>

<div
  class="knowledge-tree rounded-2xl border-2 border-white/50 p-4"
  style="background: linear-gradient(to bottom, {theme.bgFrom}, {theme.bgTo})"
>
  <div class="flex items-center gap-2 mb-3 px-2">
    <span class="text-2xl">{theme.icon}</span>
    <span class="font-bold text-gray-700">{theme.label}</span>
  </div>

  <div class="flex justify-center">
    <svg
      width={containerWidth}
      height={containerHeight}
      viewBox="0 0 {containerWidth} {containerHeight}"
      class="block"
      role="img"
      aria-label="{theme.label}学习路径"
    >
      <!-- 路径连线 -->
      {#each edges() as edge}
        {#if edge.type === 'completed'}
          <!-- 已完成：粗实线 -->
          <line
            x1={edge.from.x}
            y1={edge.from.y}
            x2={edge.to.x}
            y2={edge.to.y}
            stroke={theme.branch}
            stroke-width="4"
            opacity="0.7"
          />
        {:else if edge.type === 'current' || edge.type === 'upcoming'}
          <!-- 当前/下一个：虚线 -->
          <line
            x1={edge.from.x}
            y1={edge.from.y}
            x2={edge.to.x}
            y2={edge.to.y}
            stroke={theme.branch}
            stroke-width="3"
            stroke-dasharray="10,5"
            opacity="0.6"
          />
        {:else}
          <!-- 未解锁：淡虚线 -->
          <line
            x1={edge.from.x}
            y1={edge.from.y}
            x2={edge.to.x}
            y2={edge.to.y}
            stroke="#d1d5db"
            stroke-width="2"
            stroke-dasharray="6,4"
            opacity="0.3"
          />
        {/if}
      {/each}

      <!-- 节点 -->
      {#each pathNodes() as pn, i}
        {@const status = getNodeStatus(pn.node, i)}
        {@const isClickable = status === 'current' || status === 'completed'}
        {@const r = status === 'current' ? NODE_R + 4 : NODE_R}

        <g
          class={isClickable ? 'cursor-pointer' : ''}
          on:click={isClickable ? () => onNodeClick(pn.node.nodeId) : undefined}
          on:keydown={isClickable ? (e) => e.key === 'Enter' && onNodeClick(pn.node.nodeId) : undefined}
          role={isClickable ? 'button' : undefined}
          tabindex={isClickable ? 0 : -1}
          opacity={status === 'locked' ? 0.5 : 1}
        >
          <!-- 已完成节点光晕 -->
          {#if status === 'completed'}
            <circle cx={pn.x} cy={pn.y} r={r + 8} fill={theme.glow} opacity="0.4">
              <animate attributeName="r" values="{r + 6};{r + 12};{r + 6}" dur="2s" repeatCount="indefinite" />
              <animate attributeName="opacity" values="0.4;0.2;0.4" dur="2s" repeatCount="indefinite" />
            </circle>
          {/if}

          <!-- 当前节点脉冲 -->
          {#if status === 'current'}
            <circle cx={pn.x} cy={pn.y} r={r + 6} fill={theme.leaf} opacity="0.4">
              <animate attributeName="r" values="{r + 4};{r + 12};{r + 4}" dur="1.5s" repeatCount="indefinite" />
              <animate attributeName="opacity" values="0.5;0.2;0.5" dur="1.5s" repeatCount="indefinite" />
            </circle>
          {/if}

          <!-- 主圆圈 -->
          <circle
            cx={pn.x}
            cy={pn.y}
            r={r}
            fill={
              status === 'completed' ? theme.leafCompleted :
              status === 'current' ? theme.leaf :
              theme.leafLocked
            }
            stroke={
              status === 'completed' ? '#d97706' :
              status === 'current' ? theme.trunk :
              '#9ca3af'
            }
            stroke-width={status === 'current' ? 4 : 2.5}
          />

          <!-- 节点内容 -->
          {#if status === 'locked' || status === 'upcoming'}
            <!-- 锁图标 -->
            <text x={pn.x} y={pn.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="18" fill="#6b7280">🔒</text>
          {:else if status === 'completed'}
            <!-- 星星评级 -->
            <text x={pn.x} y={pn.y - 4} text-anchor="middle" dominant-baseline="middle" font-size="11" fill="#92400e" font-weight="bold">
              {renderStars(pn.node.starRating)}
            </text>
            <text x={pn.x} y={pn.y + 10} text-anchor="middle" font-size="12" fill="#92400e" font-weight="600">✓</text>
          {:else}
            <!-- 当前节点：显示等级 -->
            <text x={pn.x} y={pn.y + 2} text-anchor="middle" dominant-baseline="middle" font-size="14" fill="white" font-weight="bold">
              Lv{pn.node.difficulty}
            </text>
          {/if}

          <!-- 名称标签 -->
          <text
            x={pn.x}
            y={pn.y + r + 16}
            text-anchor="middle"
            font-size="11"
            fill={status === 'locked' ? '#9ca3af' : '#374151'}
            font-weight="500"
          >
            {pn.node.name}
          </text>
        </g>
      {/each}
    </svg>
  </div>

  <!-- 图例 -->
  <div class="flex items-center justify-center gap-4 mt-2 text-xs text-gray-500">
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-yellow-400 inline-block"></span> 已完成
    </span>
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-green-400 inline-block"></span> 可探险
    </span>
    <span class="flex items-center gap-1">
      <span class="w-3 h-3 rounded-full bg-gray-300 inline-block"></span> 未解锁
    </span>
  </div>
</div>
