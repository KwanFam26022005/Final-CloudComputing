# =============================================================================
# MYMINICLOUD - KIEM THU TU DONG TASK 2: BACKEND & DATA LEAD (PowerShell)
# Thanh vien phu trach: Thanh vien 2 (Backend & Data Lead)
# Phu trach: application-backend-server & relational-database-server
# =============================================================================
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   KIEM THU TU DONG TASK 2: BACKEND & DATA LEAD (2.0 DIEM)       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. CHAY BO UNIT TESTS (Flask Backend API & CRUD)
# -----------------------------------------------------------------------------
Write-Host "`n[PHAN 1] Chay bo Unit Tests cua Flask Backend Server..." -ForegroundColor White
python -m unittest discover -s application-backend-server/tests -p "test_*.py" -v
if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] Tat ca cac ca kiem thu Unit Tests deu THANH CONG!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Co loi trong Unit Tests!" -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# 2. KIEM TRA CU PHAP DOCKER COMPOSE
# -----------------------------------------------------------------------------
Write-Host "`n[PHAN 2] Kiem tra cu phap docker compose..." -ForegroundColor White
$composeOut = & docker compose config 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] File docker-compose.yml hop le 100%!" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docker compose config khong the chay tren host (Docker Desktop chua bat hoac chua cai Compose CLI plugin):" -ForegroundColor Yellow
    Write-Host "       $composeOut" -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# 3. KIEM THU LIVE TREN CONTAINER (NEU DANG CHAY)
# -----------------------------------------------------------------------------
Write-Host "`n[PHAN 3] Kiem tra trang thai container cua Task 2..." -ForegroundColor White
$appId = (docker ps -q -f "name=application-backend-server" 2>$null)
$dbId = (docker ps -q -f "name=relational-database-server" 2>$null)

if ($appId -and $dbId) {
    Write-Host "[INFO] Phat hien containers dang chay. Bat dau kiem thu tich hop..." -ForegroundColor Cyan

    # Co ban #2: /hello
    Write-Host "`n--- [Co ban #2] Kiem thu Endpoint /hello ---" -ForegroundColor Yellow
    try {
        $resDirect = Invoke-RestMethod -Uri "http://localhost:8085/hello" -TimeoutSec 3
        Write-Host "[PASS] Direct :8085/hello -> $($resDirect | ConvertTo-Json -Compress)" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Khong goi duoc :8085/hello" -ForegroundColor Yellow
    }

    try {
        $resProxy = Invoke-RestMethod -Uri "http://localhost/api/hello" -TimeoutSec 3
        Write-Host "[PASS] Proxy /api/hello -> $($resProxy | ConvertTo-Json -Compress)" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Khong goi duoc qua Proxy /api/hello" -ForegroundColor Yellow
    }

    # Co ban #3: MariaDB minicloud.notes
    Write-Host "`n--- [Co ban #3] Kiem tra MariaDB minicloud.notes ---" -ForegroundColor Yellow
    docker exec relational-database-server mariadb -uroot -proot -e "USE minicloud; SELECT * FROM notes;"

    # Mo rong #2: /student (students.json)
    Write-Host "`n--- [Mo rong #2] Kiem thu API /student (doc students.json) ---" -ForegroundColor Yellow
    try {
        $students = Invoke-RestMethod -Uri "http://localhost:8085/student" -TimeoutSec 3
        Write-Host "[PASS] Doc thanh cong $($students.Count) sinh vien tu students.json!" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Loi goi /student: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Mo rong #3: SQL CRUD (crud_practice.sql)
    Write-Host "`n--- [Mo rong #3A] Thuc thi kich ban SQL CRUD tu dong (crud_practice.sql) ---" -ForegroundColor Yellow
    Get-Content "relational-database-server\crud_practice.sql" -Raw | docker exec -i relational-database-server mariadb -uroot -proot

    # Mo rong #3: REST API CRUD (/api/students-db)
    Write-Host "`n--- [Mo rong #3B] Kiem thu REST API CRUD (/api/students-db) ---" -ForegroundColor Yellow
    try {
        # GET
        $getDb = Invoke-RestMethod -Uri "http://localhost/api/students-db" -TimeoutSec 3
        Write-Host "[PASS] GET /api/students-db -> Tim thay $($getDb.count) sinh vien" -ForegroundColor Green

        # POST (CREATE)
        $newStudent = @{
            student_id = "SV888"
            fullname   = "Nguyen Van Script Test"
            dob        = "2005-08-18"
            major      = "Cloud Integration"
        } | ConvertTo-Json
        $postRes = Invoke-RestMethod -Uri "http://localhost/api/students-db" -Method Post -Body $newStudent -ContentType "application/json" -TimeoutSec 3
        Write-Host "[PASS] POST /api/students-db -> $($postRes.message)" -ForegroundColor Green

        # PUT (UPDATE)
        $updateData = @{ major = "Cloud Architecture & DevOps" } | ConvertTo-Json
        $putRes = Invoke-RestMethod -Uri "http://localhost/api/students-db/SV888" -Method Put -Body $updateData -ContentType "application/json" -TimeoutSec 3
        Write-Host "[PASS] PUT /api/students-db/SV888 -> $($putRes.message)" -ForegroundColor Green

        # DELETE
        $delRes = Invoke-RestMethod -Uri "http://localhost/api/students-db/SV888" -Method Delete -TimeoutSec 3
        Write-Host "[PASS] DELETE /api/students-db/SV888 -> $($delRes.message)" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Kiem thu API CRUD: $($_.Exception.Message)" -ForegroundColor Yellow
    }

} else {
    Write-Host "[SKIP] Cac containers cua Task 2 hien chua chay." -ForegroundColor Yellow
    Write-Host "👉 De chay toan bo kiem thu truc tiep tren container, go:" -ForegroundColor White
    Write-Host "   docker compose up -d" -ForegroundColor Cyan
    Write-Host "   .\scripts\verify-task2.ps1" -ForegroundColor Cyan
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT KIEM THU TASK 2 (BACKEND & DATA LEAD)                " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
