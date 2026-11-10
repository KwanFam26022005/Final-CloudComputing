#!/usr/bin/env bash
# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (Bash)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
# =============================================================================
set -u

GF_AUTH="${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-admin}"

# In trạng thái UP/DOWN của từng target trong 1 job, dựa trên metric 'up' do Prometheus tự sinh
check_targets() {
  local lines
  lines=$(curl -s -G http://localhost:9090/api/v1/query --data-urlencode "query=up{job=\"$1\"}" \
    | grep -o '"instance":"[^"]*"[^]]*"[01]"\]' \
    | sed -E 's/"instance":"([^"]*)".*"([01])"\]/\1 \2/')
  if [ -z "$lines" ]; then
    echo "  [WARN] job=$1 chua co target nao (Prometheus chua chay hoac chua scrape)."
    return
  fi
  echo "$lines" | while read -r instance value; do
    if [ "$value" = "1" ]; then echo "  [PASS] job=$1 $instance -> UP"; else echo "  [FAIL] job=$1 $instance -> DOWN"; fi
  done
}

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
echo "[UI] Dang nhap Keycloak, kiem realm_52300107 / sv01 / sv02 / flask-app."

echo -e "\n[5/10] Object Storage Server (MinIO Console Port 9001)..."
curl -s -I http://localhost:9001/ | head -n 1
echo "[UI] MinIO Console: tao demo, upload index.html va tai lai de doi chieu."

echo -e "\n[6/10] Internal DNS Server (Bind9 - web-frontend-server.cloud.local)..."
docker exec internal-dns-server dig @127.0.0.1 web-frontend-server.cloud.local +short

echo -e "\n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..."
curl -s -I http://localhost:9100/metrics | head -n 1
curl -s -I http://localhost:9090/-/healthy | head -n 1
check_targets node
echo -n "  So series node_cpu_seconds_total: "
curl -s -G http://localhost:9090/api/v1/query --data-urlencode 'query=count(node_cpu_seconds_total)' \
  | grep -o '"[0-9]*"\]' | tr -d '"]'

echo -e "\n[8/10] Monitoring Grafana Dashboard (Port 3000)..."
curl -s -I http://localhost:3000/login | head -n 1
echo -n "  Datasource Prometheus: "
curl -s -u "$GF_AUTH" http://localhost:3000/api/datasources/uid/prometheus/health | grep -o '"message":"[^"]*"'
echo -n "  Dashboard: "
curl -s -u "$GF_AUTH" "http://localhost:3000/api/search?query=Node%20Exporter%20Full" | grep -o '"title":"[^"]*"' || echo "[WARN] Chua co Node Exporter Full"

echo -e "\n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..."
curl -s -I http://localhost/ | head -n 1
curl -s http://localhost/api/hello && echo ""
curl -s -I http://localhost/auth/ | head -n 1

echo -e "\n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..."
for host in web app-server db keycloak minio prometheus grafana dns-server; do
  echo "--- Ping $host ---"
  docker exec object-storage-server ping -c 2 "$host"
done

echo -e "\n================================================================="
echo "   HOAN TAT KIEM THU PHAN CO BAN!                                "
echo "================================================================="
