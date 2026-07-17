#!/bin/bash
# Pet Grow Up: Windows 开发 -> WSL 同步 -> Docker 部署
set -e

WSL_DIR="/home/fxb_2/pet-grow-up"
WIN_DIR="/mnt/d/ALAN/Codes/pet-grow-up"

echo "======================================"
echo "  Pet Grow Up 同步部署"
echo "======================================"

# 1. 同步 Windows -> WSL（排除构建产物和依赖）
echo ">>> [1/4] 同步 Windows -> WSL..."
mkdir -p "$WSL_DIR"
rsync -av --delete \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='backend/target' \
  --exclude='frontend/build' \
  --exclude='frontend/.svelte-kit' \
  "$WIN_DIR/" "$WSL_DIR/"

cd "$WSL_DIR"

# 2. 停止旧容器
echo ">>> [2/4] 停止旧容器..."
docker compose -f docker-compose.dev.yml down

# 3. 构建后端 JAR（在 WSL 中编译）
echo ">>> [3/4] 构建后端 JAR..."
cd backend && mvn clean package -DskipTests -B -q && cd ..

# 4. 构建镜像并启动
echo ">>> [4/4] 构建并启动..."
docker compose -f docker-compose.dev.yml up --build -d
sleep 15

echo ""
echo "======================================"
echo "  部署完成!"
echo "======================================"
docker ps --filter "name=petgrowup"
echo ""
echo "🔗 http://localhost:3000 | admin / admin123"
echo ""
echo "💡 日常开发:"
echo "   Windows 改代码 -> 保存 -> 运行 bash dev.sh"
echo "   前端修改自动热重载，后端修改需: docker compose -f docker-compose.dev.yml restart backend"
echo "======================================"
