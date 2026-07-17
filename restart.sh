#!/bin/bash
# Pet Grow Up 重启脚本
# 用法: bash restart.sh [frontend|backend|all]

set -e

PROJECT_DIR="$(dirname "$(readlink -f "$0")")"
cd "$PROJECT_DIR"

MODE=${1:-all}

echo "======================================"
echo "  Pet Grow Up 重启服务"
echo "======================================"
echo "项目目录: $PROJECT_DIR"
echo "重启模式: $MODE"
echo ""

case $MODE in
  frontend)
    echo ">>> 重新构建前端..."
    cd frontend && npm run build && cd ..
    echo ">>> 重启前端容器..."
    docker compose restart frontend
    ;;
  backend)
    echo ">>> 重新构建后端 JAR..."
    cd backend && mvn clean package -DskipTests -B -q && cd ..
    echo ">>> 重启后端容器..."
    docker compose restart backend
    ;;
  all|*)
    echo ">>> 重新构建后端 JAR..."
    cd backend && mvn clean package -DskipTests -B -q && cd ..
    echo ">>> 重新构建前端..."
    cd frontend && npm run build && cd ..
    echo ">>> 重启所有容器..."
    docker compose restart
    ;;
esac

# 等待服务就绪
echo ">>> 等待服务就绪..."
sleep 10

# 显示状态
echo ""
echo "======================================"
echo "  服务状态"
echo "======================================"
docker compose ps
echo ""
echo "前端: http://localhost:3000"
echo "后端: http://localhost:8080"
echo "======================================"