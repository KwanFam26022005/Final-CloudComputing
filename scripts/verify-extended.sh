#!/usr/bin/env bash
# =============================================================================
# MYMINICLOUD - AUTOMATED EXTENDED VERIFICATION SCRIPT (Bash)
# Kiểm thử tự động 10 hạng mục Mở rộng (5.0 điểm)
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
echo "   MYMINICLOUD - KIEM THU TU DONG 10 MUC MO RONG (5.0 DIEM)      "
echo "================================================================="

echo -e "\n[Mo rong #1] Web Frontend Blog 3 bai viet HTML..."
for page in blog1.html blog2.html blog3.html; do
  code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "http://localhost:8080/blog/$page")
  if [ "$code" = "200" ]; then pass "/blog/$page -> HTTP $code"; else fail "/blog/$page -> HTTP $code"; fi
done

echo -e "\n[Mo rong #2] Backend API /student (tu students.json)..."
N=$(curl -s -m 5 http://localhost/api/student | grep -o '"id"' | wc -l | tr -d ' ')
if [ "$N" -eq 5 ]; then pass "/api/student tra ve $N sinh vien."; else fail "/api/student tra ve $N sinh vien (ky vong 5)."; fi

echo -e "\n[Mo rong #3] Database studentdb.students & API /api/students-db..."
docker exec relational-database-server mariadb -uroot "-p${DB_PASS}" -e "USE studentdb; SELECT * FROM students;"
if [ $? -eq 0 ]; then pass "studentdb.students truy van duoc"; else fail "studentdb.students khong truy van duoc"; fi
SDB=$(curl -s -m 5 http://localhost/api/students-db)
echo "$SDB"
SDB_N=$(grep -Eo '"count": *[0-9]+' <<<"$SDB" | grep -Eo '[0-9]+$' | head -n 1)
if [ -n "$SDB_N" ] && [ "$SDB_N" -ge 3 ]; then
  pass "/api/students-db tra ve $SDB_N ban ghi tu MariaDB."
else
  fail "/api/students-db tra ve count='${SDB_N:-?}' (ky vong >= 3)."
fi

echo -e "\n[Mo rong #4] Keycloak OIDC Realm realm_52300107 + Token + /api/secure..."
TOKEN=$(curl -s -m 10 -X POST "http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=flask-app" \
  -d "username=sv01" \
  -d "password=sv01pass" \
  -d "grant_type=password" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  SEC=$(curl -s -m 5 -H "Authorization: Bearer $TOKEN" http://localhost/api/secure)
  echo "$SEC"
  if grep -Eq '"preferred_username": *"sv01"' <<<"$SEC"; then
    pass "OIDC /api/secure OK -> preferred_username=sv01"
  else
    fail "OIDC /api/secure -> preferred_username khac sv01"
  fi
else
  fail "Chua lay duoc token (Keycloak co the dang khoi dong)."
fi

# Mo rong 5: kiem tra anh public va minh chung PDF tren Console.
echo -e "\n[Mo rong #5] MinIO avatar va PDF bao cao..."
code=$(curl -s --max-time 20 -o /dev/null -w '%{http_code}' http://localhost:9000/profile-pics/avatar.jpg)
if [ "$code" = "200" ]; then pass "Avatar HTTP $code"; else fail "Avatar chua doc public duoc (HTTP $code)."; fi
echo "[UI] Mo avatar an danh; trong documents kiem PDF bao cao, tai ve va mo noi dung."

echo -e "\n[Mo rong #6] Internal DNS (app-backend, minio, keycloak.cloud.local)..."
for pair in web-frontend-server.cloud.local=10.10.10.10 app-backend.cloud.local=10.10.10.20 \
            minio.cloud.local=10.10.10.30 keycloak.cloud.local=10.10.10.40; do
  name="${pair%%=*}"; want="${pair##*=}"
  ans=$(docker exec internal-dns-server dig @127.0.0.1 "$name" +short 2>&1 | tr -d '\r')
  echo "  $name -> $ans"
  if [ "$ans" = "$want" ]; then pass "$name -> $ans"; else fail "$name -> '$ans' (ky vong $want)"; fi
done

echo -e "\n[Mo rong #7] Prometheus Scrape Target 'web' (web-frontend-server:80/metrics)..."
check_targets web 2

echo -e "\n[Mo rong #8] Grafana Dashboard 'System Health of <MSSV>' (3 bieu do)..."
DASH_UID=$(curl -s -m 5 -u "$GF_AUTH" "http://localhost:3000/api/search?query=System%20Health%20of" | grep -o '"uid":"[^"]*"' | head -n 1 | cut -d'"' -f4)
if [ -n "$DASH_UID" ]; then
  DASH=$(curl -s -m 5 -u "$GF_AUTH" "http://localhost:3000/api/dashboards/uid/$DASH_UID")
  echo "  Dashboard uid=$DASH_UID:"
  grep -o '"title":"[^"]*"' <<<"$DASH" | sed 's/^/    /'
  PANELS=$(grep -o '"gridPos"' <<<"$DASH" | wc -l | tr -d ' ')
  if [ "$PANELS" -ge 3 ]; then pass "Dashboard co $PANELS bieu do"; else fail "Dashboard chi co $PANELS bieu do (ky vong >= 3)"; fi
else
  fail "Khong tim thay dashboard 'System Health of <MSSV>'."
fi

echo -e "\n[Mo rong #9] API Gateway Route /student/..."
N=$(curl -s -m 5 http://localhost/student/ | grep -o '"id"' | wc -l | tr -d ' ')
if [ "$N" -eq 5 ]; then pass "http://localhost/student/ tra ve $N sinh vien."; else fail "http://localhost/student/ tra ve $N sinh vien (ky vong 5)."; fi

echo -e "\n[Mo rong #10] Load Balancing Round Robin (web-frontend-server1 & 2)..."
SEEN=""
for i in 1 2 3 4 5 6; do
  hdr=$(curl -s -m 5 -I http://localhost/ | grep -i "X-Served-By" | tr -d '\r')
  echo "Request #$i -> $hdr"
  SEEN="$SEEN $hdr"
done
if grep -q "web-frontend-server1" <<<"$SEEN" && grep -q "web-frontend-server2" <<<"$SEEN"; then
  pass "Round Robin: thay ca web-frontend-server1 va web-frontend-server2"
else
  fail "Round Robin: khong thay ca server1 va server2"
fi

echo -e "\n================================================================="
echo "   HOAN TAT KIEM THU PHAN MO RONG!                               "
echo "================================================================="
echo "SUMMARY: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
