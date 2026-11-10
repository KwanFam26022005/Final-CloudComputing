#!/usr/bin/env bash
# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (Bash)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
# Cuối script in "SUMMARY: PASS=x FAIL=y" và exit 1 nếu có FAIL.
# =============================================================================
set -u

GF_AUTH="${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-admin}"
DB_PASS="${MARIADB_ROOT_PASSWORD:-root}"

# Bộ đếm kết quả
PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  [PASS] $*"; }
fail() { FAIL=$((FAIL + 1)); echo "  [FAIL] $*"; }

# Kiem tra HTTP 200 va (neu co) noi dung phai chua chuoi $3. Theo redirect (-L).
check_url() {
  local name="$1" url="$2" contains="${3:-}" out code body
  out=$(curl -s -L -m 5 -w '\n%{http_code}' "$url") || { fail "$name -> Khong truy cap duoc ($url)"; return; }
  code=$(echo "$out" | tail -n 1)
  body=$(echo "$out" | sed '$d')
  if [ "$code" != "200" ]; then
    fail "$name -> HTTP $code ($url)"
  elif [ -n "$contains" ] && ! grep -qF "$contains" <<<"$body"; then
    fail "$name -> HTTP 200 nhung thieu noi dung '$contains' ($url)"
  elif [ -n "$contains" ]; then
    pass "$name -> HTTP 200, co '$contains' ($url)"
  else
    pass "$name -> HTTP 200 ($url)"
  fi
}

# In trạng thái UP/DOWN của từng target trong 1 job, dựa trên metric 'up' do Prometheus tự sinh
# Phải có đủ $2 target (mặc định 1) và tất cả đều UP.
check_targets() {
  local lines expected="${2:-1}" n=0 instance value
  lines=$(curl -s -m 5 -G http://localhost:9090/api/v1/query --data-urlencode "query=up{job=\"$1\"}" \
    | grep -o '"instance":"[^"]*"[^]]*"[01]"\]' \
    | sed -E 's/"instance":"([^"]*)".*"([01])"\]/\1 \2/')
  if [ -n "$lines" ]; then
    while read -r instance value; do
      n=$((n + 1))
      if [ "$value" = "1" ]; then pass "job=$1 $instance -> UP"; else fail "job=$1 $instance -> DOWN"; fi
    done <<<"$lines"
  fi
  if [ "$n" -lt "$expected" ]; then
    fail "job=$1 chi co $n/$expected target (Prometheus chua chay hoac chua scrape)."
  fi
}

echo "================================================================="
echo "   MYMINICLOUD - KIEM THU TU DONG PHAN CO BAN (5.0 DIEM)         "
echo "================================================================="

echo -e "\n[1/10] Web Frontend Server (Port 8080)..."
check_url "Web Home (/)" http://localhost:8080/
check_url "Web Blog (/blog/)" http://localhost:8080/blog/

echo -e "\n[2/10] Application Backend Server (/hello)..."
check_url "App Direct (8085/hello)" http://localhost:8085/hello "Hello from App Server!"
check_url "App via Proxy (/api/hello)" http://localhost/api/hello "Hello from App Server!"

echo -e "\n[3/10] Relational Database Server (MariaDB minicloud.notes)..."
NOTES=$(docker exec relational-database-server mariadb -uroot "-p${DB_PASS}" -e "USE minicloud; SELECT * FROM notes;" 2>&1)
rc=$?
echo "$NOTES"
if [ "$rc" -eq 0 ] && grep -qF "Hello from MariaDB!" <<<"$NOTES"; then
  pass "minicloud.notes co 'Hello from MariaDB!'"
else
  fail "minicloud.notes khong co 'Hello from MariaDB!' (exit=$rc)"
fi

echo -e "\n[4/10] Authentication Identity Server (Keycloak Port 8081)..."
check_url "Keycloak Console" http://localhost:8081/
echo "[UI] Dang nhap Keycloak, kiem realm_52300107 / sv01 / sv02 / flask-app."

echo -e "\n[5/10] Object Storage Server (MinIO Console Port 9001)..."
check_url "MinIO Console" http://localhost:9001/
echo "[UI] MinIO Console: tao demo, upload index.html va tai lai de doi chieu."

echo -e "\n[6/10] Internal DNS Server (Bind9 - web-frontend-server.cloud.local)..."
DNS=$(docker exec internal-dns-server dig @127.0.0.1 web-frontend-server.cloud.local +short 2>&1 | tr -d '\r')
echo "$DNS"
if [ "$DNS" = "10.10.10.10" ]; then
  pass "web-frontend-server.cloud.local -> 10.10.10.10"
else
  fail "web-frontend-server.cloud.local -> '$DNS' (ky vong 10.10.10.10)"
fi

echo -e "\n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..."
check_url "Node Exporter Metrics" http://localhost:9100/metrics
check_url "Prometheus Health" http://localhost:9090/-/healthy
check_targets node 1
CPU_N=$(curl -s -m 5 -G http://localhost:9090/api/v1/query --data-urlencode 'query=count(node_cpu_seconds_total)' \
  | grep -o '"[0-9]*"\]' | tr -d '"]')
if [ -n "$CPU_N" ] && [ "$CPU_N" -gt 0 ]; then
  pass "node_cpu_seconds_total co $CPU_N series."
else
  fail "node_cpu_seconds_total khong co du lieu."
fi

echo -e "\n[8/10] Monitoring Grafana Dashboard (Port 3000)..."
check_url "Grafana UI" http://localhost:3000/login
DS=$(curl -s -m 5 -u "$GF_AUTH" http://localhost:3000/api/datasources/uid/prometheus/health)
if grep -Eq '"status": *"OK"' <<<"$DS"; then
  pass "Datasource Prometheus -> $(grep -o '"message":"[^"]*"' <<<"$DS")"
else
  fail "Datasource Prometheus -> $DS"
fi
NEF=$(curl -s -m 5 -u "$GF_AUTH" "http://localhost:3000/api/search?query=Node%20Exporter%20Full" | grep -o '"title":"[^"]*"' | head -n 1)
if [ -n "$NEF" ]; then pass "Dashboard $NEF da co san."; else fail "Chua co dashboard Node Exporter Full"; fi

echo -e "\n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..."
check_url "Gateway Web (/)" http://localhost/
check_url "Gateway API (/api/hello)" http://localhost/api/hello "Hello from App Server!"
AUTH_OUT=$(curl -s -m 5 -o /dev/null -w '%{http_code} %{redirect_url}' http://localhost/auth/)
AUTH_CODE="${AUTH_OUT%% *}"
case "$AUTH_CODE" in
  30[1-8]) pass "Gateway Auth (/auth/) -> HTTP $AUTH_CODE, Location: ${AUTH_OUT#* }" ;;
  *) fail "Gateway Auth (/auth/) -> HTTP $AUTH_CODE, ky vong redirect 3xx" ;;
esac

echo -e "\n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..."
for host in web app-server db keycloak minio prometheus grafana dns-server; do
  echo "--- Ping $host ---"
  if docker exec object-storage-server ping -c 2 "$host"; then pass "ping $host"; else fail "ping $host"; fi
done

echo -e "\n================================================================="
echo "   HOAN TAT KIEM THU PHAN CO BAN!                                "
echo "================================================================="
echo "SUMMARY: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
