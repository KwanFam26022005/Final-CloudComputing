#!/usr/bin/env bash
# =============================================================================
# MYMINICLOUD - AUTOMATED EXTENDED VERIFICATION SCRIPT (Bash)
# Kiểm thử tự động 10 hạng mục Mở rộng (5.0 điểm)
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
echo "   MYMINICLOUD - KIEM THU TU DONG 10 MUC MO RONG (5.0 DIEM)      "
echo "================================================================="

echo -e "\n[Mo rong #1] Web Frontend Blog 3 bai viet HTML..."
for page in blog1.html blog2.html blog3.html; do
  echo -n "/blog/$page -> "
  curl -s -I "http://localhost:8080/blog/$page" | head -n 1
done

echo -e "\n[Mo rong #2] Backend API /student (tu students.json)..."
curl -s http://localhost/api/student | head -n 20 && echo ""

echo -e "\n[Mo rong #3] Database studentdb.students & API /api/students-db..."
docker exec relational-database-server mariadb -uroot -proot -e "USE studentdb; SELECT * FROM students;"
curl -s http://localhost/api/students-db && echo ""

echo -e "\n[Mo rong #4] Keycloak OIDC Realm realm_sv001 + Token + /api/secure..."
TOKEN=$(curl -s -X POST "http://localhost:8081/realms/realm_sv001/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=flask-app" \
  -d "username=sv01" \
  -d "password=sv01pass" \
  -d "grant_type=password" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  curl -s -H "Authorization: Bearer $TOKEN" http://localhost/api/secure && echo ""
else
  echo "[WARN] Chua lay duoc token (Keycloak co the dang khoi dong)."
fi

echo -e "\n[Mo rong #6] Internal DNS (app-backend, minio, keycloak.cloud.local)..."
docker run --rm --network cloud-net internetsystemsconsortium/bind9:9.18 sh -c '
  dig @dns-server app-backend.cloud.local +short
  dig @dns-server minio.cloud.local +short
  dig @dns-server keycloak.cloud.local +short
'

echo -e "\n[Mo rong #7] Prometheus Scrape Target 'web' (web-frontend-server:80/metrics)..."
check_targets web

echo -e "\n[Mo rong #8] Grafana Dashboard 'System Health of <MSSV>' (3 bieu do)..."
DASH_UID=$(curl -s -u "$GF_AUTH" "http://localhost:3000/api/search?query=System%20Health%20of" | grep -o '"uid":"[^"]*"' | head -n 1 | cut -d'"' -f4)
if [ -n "$DASH_UID" ]; then
  echo "  Dashboard uid=$DASH_UID:"
  curl -s -u "$GF_AUTH" "http://localhost:3000/api/dashboards/uid/$DASH_UID" | grep -o '"title":"[^"]*"' | sed 's/^/    /'
else
  echo "  [WARN] Khong tim thay dashboard 'System Health of <MSSV>'."
fi

echo -e "\n[Mo rong #9] API Gateway Route /student/..."
curl -s http://localhost/student/ | head -n 20 && echo ""

echo -e "\n[Mo rong #10] Load Balancing Round Robin (web-frontend-server1 & 2)..."
for i in 1 2 3 4; do
  echo -n "Request #$i -> "
  curl -s -I http://localhost/ | grep -i "X-Served-By"
done

echo -e "\n================================================================="
echo "   HOAN TAT KIEM THU PHAN MO RONG!                               "
echo "================================================================="
