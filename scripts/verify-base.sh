#!/usr/bin/env bash
# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (Bash)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
# =============================================================================
set -u

echo "================================================================="
echo "   MYMINICLOUD - KIEM THU TU DONG PHAN CO BAN (5.0 DIEM)         "
echo "================================================================="

echo -e "\n[1/10] Web Frontend Server (Port 8080)..."
curl -s -I http://localhost:8080/ | head -n 1
curl -s -I http://localhost:8080/blog/ | head -n 1

echo -e "\n[2/10] Application Backend Server (/hello)..."
curl -s http://localhost:8085/hello && echo ""
curl -s http://localhost/api/hello && echo ""

echo -e "\n[3/10] Relational Database Server (MariaDB minicloud.notes)..."
docker exec relational-database-server mariadb -uroot -proot -e "USE minicloud; SELECT * FROM notes;"

echo -e "\n[4/10] Authentication Identity Server (Keycloak Port 8081)..."
curl -s -I http://localhost:8081/ | head -n 1

echo -e "\n[5/10] Object Storage Server (MinIO Console Port 9001)..."
curl -s -I http://localhost:9001/ | head -n 1

echo -e "\n[6/10] Internal DNS Server (Bind9 - web-frontend-server.cloud.local)..."
docker run --rm --network cloud-net internetsystemsconsortium/bind9:9.18 dig @dns-server web-frontend-server.cloud.local +short

echo -e "\n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..."
curl -s -I http://localhost:9100/metrics | head -n 1
curl -s -I http://localhost:9090/-/healthy | head -n 1

echo -e "\n[8/10] Monitoring Grafana Dashboard (Port 3000)..."
curl -s -I http://localhost:3000/login | head -n 1

echo -e "\n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..."
curl -s -I http://localhost/ | head -n 1
curl -s http://localhost/api/hello && echo ""
curl -s -I http://localhost/auth/ | head -n 1

echo -e "\n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..."
for host in web app-server db keycloak minio prometheus grafana dns-server; do
  echo "--- Ping $host ---"
  docker exec api-gateway-proxy-server ping -c 2 "$host"
done

echo -e "\n================================================================="
echo "   HOAN TAT KIEM THU PHAN CO BAN!                                "
echo "================================================================="
