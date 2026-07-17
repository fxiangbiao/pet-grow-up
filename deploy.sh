#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0")")"

echo "=== Pet Grow Up 部署 ==="
echo "项目目录: $(pwd)"

docker compose down

cd backend && mvn clean package -DskipTests -B -q && cd ..

cd frontend && npm run build && cd ..

docker compose up --build -d

sleep 15

echo "=== 服务状态 ==="
docker compose ps
echo ""
echo "前端: http://localhost:3000"
echo "后端: http://localhost:8080"
echo "账号: admin / admin123"