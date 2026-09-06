#!/usr/bin/env bash
# ============================================================
#  Pet Grow Up · 一键部署/运维脚本（统一入口）
#  用法: bash petgrowup.sh <命令> [参数]
#
#  命令:
#    sync            同步 Windows 源码 -> WSL 部署目录
#    dev-up          构建并启动【开发】栈 (docker-compose.dev.yml, 前端热重载)
#    dev-down        停止开发栈
#    dev-restart [s] 重启开发栈服务 s (backend|frontend|mysql|all)
#    prod-up         构建并启动【生产】栈 (docker-compose.yml)
#    prod-down       停止生产栈
#    prod-restart [s] 重启生产栈服务
#    status / ps     查看容器状态
#    logs [service]  跟踪日志 (backend|frontend|mysql)
#    docker-up       启动 WSL 内 docker daemon（幂等）
#
#  说明:
#    - 本脚本可放在任意位置；Windows 侧建议直接用仓库里的原始文件：
#        wsl -u root -e bash /mnt/d/ALAN/Codes/pet-grow-up/petgrowup.sh dev-up
#    - 首次使用会先执行 sync 把源码同步进 WSL 部署目录，再在 WSL 内 docker 部署。
#    - 可配置: WIN_DIR（Windows 源码）、WSL_DIR（WSL 部署目录）。
#    - 后端容器内 JRE 为 17，与 pom <java.version>17 一致。
# ============================================================
set -e

# ---- 可配置路径 -------------------------------------------------
WIN_DIR="${PETGROWUP_WIN_DIR:-/mnt/d/ALAN/Codes/pet-grow-up}"
WSL_DIR="${PETGROWUP_WSL_DIR:-/home/fxb_2/pet-grow-up}"
MYSQL_NAME="petgrowup-mysql"

need_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "✗ 未找到 docker。请在 WSL(Ubuntu) 内运行本脚本，或先 wsl --install"
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "✗ docker daemon 未运行，先执行: bash petgrowup.sh docker-up"
    exit 1
  fi
}

# 启动 docker daemon（幂等）
docker-up() {
  if docker info >/dev/null 2>&1; then
    echo "✓ docker daemon 已在运行"
    return
  fi
  echo ">>> 启动 docker daemon..."
  service docker start 2>/dev/null || sudo service docker start
  sleep 4
  docker info >/dev/null 2>&1 && echo "✓ docker daemon 已就绪" || { echo "✗ 启动失败，请手动执行: sudo service docker start"; exit 1; }
}

# 清理与 compose 同名的「孤儿」容器（非 compose 管理时会阻塞 up）
ensure_mysql_name_free() {
  if docker ps -a --format '{{.Names}}' | grep -qx "$MYSQL_NAME"; then
    local proj
    proj=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$MYSQL_NAME" 2>/dev/null || true)
    if [ -z "$proj" ] || [ "$proj" = "<no value>" ]; then
      echo "⚠  存在同名但非 compose 管理的容器 $MYSQL_NAME，删除后由 compose 重建。"
      docker rm -f "$MYSQL_NAME"
    fi
  fi
}

# Windows -> WSL 同步源码
sync() {
  if [ ! -d "$WIN_DIR" ]; then
    echo "✗ 找不到 Windows 源码目录: $WIN_DIR"
    echo "  可设置环境变量 PETGROWUP_WIN_DIR 指定实际路径。"
    exit 1
  fi
  mkdir -p "$WSL_DIR"
  echo ">>> [1/3] 同步 $WIN_DIR -> $WSL_DIR ..."
  rsync -a --delete \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='.qoder-cn' \
    --exclude='.workbuddy' \
    --exclude='.superpowers' \
    --exclude='.claude' \
    --exclude='backend/target' \
    --exclude='frontend/build' \
    --exclude='frontend/.svelte-kit' \
    --exclude='frontend/node_modules' \
    --exclude='godot/.godot' \
    --exclude='*.log' \
    --exclude='.smoke-*' \
    --exclude='.check-*.py' \
    --exclude='.mysql-*.py' \
    "$WIN_DIR/" "$WSL_DIR/"
  echo "✓ 同步完成 → $WSL_DIR"
}

# 构建并启动
up() {
  local compose="$1" label="$2"
  need_docker
  sync
  ensure_mysql_name_free
  echo ">>> [$label] 构建后端 JAR（WSL 内 maven）..."
  (cd "$WSL_DIR/backend" && mvn clean package -DskipTests -B -q)
  echo ">>> [$label] compose 构建并启动..."
  (cd "$WSL_DIR" && docker compose -f "$compose" up --build -d)
  echo ">>> 等待服务就绪..."
  sleep 15
  status
  echo ""
  echo "🔗 前端: http://localhost:3000   后端: http://localhost:8080"
  echo "   管理后台账号: admin / admin123"
  echo "💡 日常：改代码后 bash petgrowup.sh sync（前端 dev 模式自动热更；后端需 dev-restart backend）"
}

down() {
  local compose="$1"
  need_docker
  (cd "$WSL_DIR" && docker compose -f "$compose" down)
  echo "✓ 已停止"
}

restart() {
  local compose="$1" svc="$2"
  need_docker
  if [ "$svc" = "backend" ]; then
    echo ">>> 重新打包 JAR 并重建后端镜像..."
    (cd "$WSL_DIR/backend" && mvn clean package -DskipTests -B -q)
    (cd "$WSL_DIR" && docker compose -f "$compose" up --build -d backend)
  else
    (cd "$WSL_DIR" && docker compose -f "$compose" restart "$svc")
  fi
  echo "✓ 已重启 ${svc:-全部服务}"
}

status() {
  need_docker
  echo "---- docker compose (dev) ----"
  (cd "$WSL_DIR" && docker compose -f "$WSL_DIR/docker-compose.dev.yml" ps 2>/dev/null || echo "（无 dev 栈）")
  echo ""
  echo "---- 本机 petgrowup 相关容器 ----"
  docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'NAMES|petgrowup' || echo "（无）"
}

logs() {
  need_docker
  (cd "$WSL_DIR" && docker compose -f "$WSL_DIR/docker-compose.dev.yml" logs -f --tail 100 "${1:-backend}")
}

CMD="${1:-help}"
shift || true

case "$CMD" in
  sync) sync ;;
  dev-up) up "$WSL_DIR/docker-compose.dev.yml" "dev" ;;
  dev-down) down "$WSL_DIR/docker-compose.dev.yml" ;;
  dev-restart) restart "$WSL_DIR/docker-compose.dev.yml" "${1:-all}" ;;
  prod-up) up "$WSL_DIR/docker-compose.yml" "prod" ;;
  prod-down) down "$WSL_DIR/docker-compose.yml" ;;
  prod-restart) restart "$WSL_DIR/docker-compose.yml" "${1:-all}" ;;
  docker-up) docker-up ;;
  status|ps) status ;;
  logs) logs "${1:-backend}" ;;
  help|--help|-h)
    sed -n '2,30p' "$0" | sed 's/^#\{0,1\} *//' ;;
  *) echo "未知命令: $CMD（试试 bash petgrowup.sh help）"; exit 1 ;;
esac
