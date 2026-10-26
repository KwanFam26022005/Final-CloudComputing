#!/bin/bash
# =============================================================================
# MYMINICLOUD - KIEM THU TU DONG TASK 2: BACKEND & DATA LEAD (Bash)
# Thanh vien phu trach: Thanh vien 2 (Backend & Data Lead)
# =============================================================================

echo "================================================================="
echo "   KIEM THU TU DONG TASK 2: BACKEND & DATA LEAD (2.0 DIEM)       "
echo "================================================================="

# 1. Chay Unit Tests
echo ""
echo "[PHAN 1] Chay bo Unit Tests cua Flask Backend Server..."
python3 -m unittest discover -s application-backend-server/tests -p "test_*.py" -v
if [ $? -eq 0 ]; then
    echo ">>> [PASS] Tat ca cac ca kiem thu Unit Tests deu THANH CONG!"
else
    echo ">>> [FAIL] Co loi trong Unit Tests!"
fi

# 2. Kiem tra cu phap docker compose
echo ""
echo "[PHAN 2] Kiem tra cu phap docker compose..."
if command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

$COMPOSE_CMD config >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo ">>> [PASS] File docker-compose.yml hop le 100%!"
else
    echo ">>> [SKIP] $COMPOSE_CMD config khong the chay tren host (Docker chua bat hoac thieu Compose plugin)."
fi

# 3. Kiem thu Live tren Container (neu dang chay)
echo ""
echo "[PHAN 3] Kiem tra trang thai container cua Task 2..."
APP_ID=$(docker ps -q -f "name=application-backend-server" 2>/dev/null)
DB_ID=$(docker ps -q -f "name=relational-database-server" 2>/dev/null)

if [ -n "$APP_ID" ] && [ -n "$DB_ID" ]; then
    echo ">>> [INFO] Phat hien containers dang chay. Bat dau kiem thu tich hop..."

    echo ""
    echo "--- [Co ban #2] Kiem thu Endpoint /hello ---"
    curl -s http://localhost:8085/hello && echo ""
    curl -s http://localhost/api/hello && echo ""

    echo ""
    echo "--- [Co ban #3] Kiem tra MariaDB minicloud.notes ---"
    docker exec relational-database-server mariadb -uroot -proot -e "USE minicloud; SELECT * FROM notes;"

    echo ""
    echo "--- [Mo rong #2] Kiem thu API /student (doc students.json) ---"
    curl -s http://localhost:8085/student && echo ""

    echo ""
    echo "--- [Mo rong #3A] Thuc thi kich ban SQL CRUD tu dong (crud_practice.sql) ---"
    docker exec -i relational-database-server mariadb -uroot -proot < relational-database-server/crud_practice.sql

    echo ""
    echo "--- [Mo rong #3B] Kiem thu REST API CRUD (/api/students-db) ---"
    curl -s http://localhost/api/students-db && echo ""
    curl -s -X POST http://localhost/api/students-db \
      -H "Content-Type: application/json" \
      -d '{"student_id":"SV888","fullname":"Nguyen Van Script Test","dob":"2005-08-18","major":"Cloud Integration"}' && echo ""
    curl -s -X PUT http://localhost/api/students-db/SV888 \
      -H "Content-Type: application/json" \
      -d '{"major":"Cloud Architecture & DevOps"}' && echo ""
    curl -s -X DELETE http://localhost/api/students-db/SV888 && echo ""
else
    echo ">>> [SKIP] Containers cua Task 2 hien chua chay."
    echo "👉 De chay toan bo kiem thu truc tiep tren container, go:"
    echo "   docker compose up -d"
    echo "   ./scripts/verify-task2.sh"
fi

echo ""
echo "================================================================="
echo "   HOAN TAT KIEM THU TASK 2 (BACKEND & DATA LEAD)                "
echo "================================================================="
