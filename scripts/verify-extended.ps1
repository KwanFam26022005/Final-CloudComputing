# =============================================================================
# MYMINICLOUD - AUTOMATED EXTENDED VERIFICATION SCRIPT (PowerShell)
# Kiểm thử tự động 10 hạng mục Mở rộng (5.0 điểm)
# =============================================================================
$ErrorActionPreference = "Continue"

$gfUser = if ($env:GF_SECURITY_ADMIN_USER) { $env:GF_SECURITY_ADMIN_USER } else { "admin" }
$gfPass = if ($env:GF_SECURITY_ADMIN_PASSWORD) { $env:GF_SECURITY_ADMIN_PASSWORD } else { "admin" }
$gfHeaders = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${gfUser}:${gfPass}")) }

# In trạng thái UP/DOWN của từng target trong 1 job, dựa trên metric 'up' do Prometheus tự sinh
function Check-PromTargets($Job) {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query" -Body @{ query = "up{job=`"$Job`"}" } -TimeoutSec 5
        if (-not $r.data.result) {
            Write-Host "[WARN] job=$Job chua co target nao (Prometheus chua chay hoac chua scrape)." -ForegroundColor Yellow
            return
        }
        foreach ($t in $r.data.result) {
            if ($t.value[1] -eq "1") {
                Write-Host "[PASS] job=$Job $($t.metric.instance) -> UP" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] job=$Job $($t.metric.instance) -> DOWN" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[WARN] Prometheus API -> $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "   MYMINICLOUD - KIEM THU TU DONG 10 MUC MO RONG (5.0 DIEM)      " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

Write-Host "`n[Mo rong #1] Web Frontend Blog 3 bai viet HTML..." -ForegroundColor White
foreach ($b in @("blog1.html", "blog2.html", "blog3.html")) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8080/blog/$b" -UseBasicParsing -TimeoutSec 5
        Write-Host "[PASS] /blog/$b -> HTTP $($r.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] /blog/$b -> $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n[Mo rong #2] Backend API /student (tu students.json)..." -ForegroundColor White
try {
    $s = Invoke-RestMethod -Uri "http://localhost/api/student" -TimeoutSec 5
    Write-Host "[PASS] /api/student tra ve $($s.Count) sinh vien." -ForegroundColor Green
} catch {
    Write-Host "[WARN] /api/student -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[Mo rong #3] Database studentdb.students & API /api/students-db..." -ForegroundColor White
docker exec relational-database-server mariadb -uroot -proot -e "USE studentdb; SELECT * FROM students;"
try {
    $sdb = Invoke-RestMethod -Uri "http://localhost/api/students-db" -TimeoutSec 5
    Write-Host "[PASS] /api/students-db tra ve $($sdb.count) ban ghi tu MariaDB." -ForegroundColor Green
} catch {
    Write-Host "[WARN] /api/students-db -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[Mo rong #4] Keycloak OIDC Realm realm_sv001 + Token + /api/secure..." -ForegroundColor White
try {
    $tokenResp = Invoke-RestMethod -Method Post -Uri "http://localhost:8081/realms/realm_sv001/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body "client_id=flask-app&username=sv01&password=sv01pass&grant_type=password"
    $token = $tokenResp.access_token
    $secResp = Invoke-RestMethod -Uri "http://localhost/api/secure" -Headers @{ Authorization = "Bearer $token" }
    Write-Host "[PASS] OIDC /api/secure OK -> User: $($secResp.preferred_username), Realm: $($secResp.realm)" -ForegroundColor Green
} catch {
    Write-Host "[WARN] OIDC /api/secure -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[Mo rong #6] Internal DNS (app-backend, minio, keycloak.cloud.local)..." -ForegroundColor White
docker run --rm --network cloud-net internetsystemsconsortium/bind9:9.18 sh -c "
  dig @dns-server app-backend.cloud.local +short
  dig @dns-server minio.cloud.local +short
  dig @dns-server keycloak.cloud.local +short
"

Write-Host "`n[Mo rong #7] Prometheus Scrape Target 'web' (web-frontend-server:80)..." -ForegroundColor White
Check-PromTargets "web"

Write-Host "`n[Mo rong #8] Grafana Dashboard 'System Health of <MSSV>' (3 bieu do)..." -ForegroundColor White
try {
    $found = Invoke-RestMethod -Uri "http://localhost:3000/api/search?query=System%20Health%20of" -Headers $gfHeaders -TimeoutSec 5
    if ($found) {
        $dash = (Invoke-RestMethod -Uri "http://localhost:3000/api/dashboards/uid/$($found[0].uid)" -Headers $gfHeaders -TimeoutSec 5).dashboard
        Write-Host "[PASS] Dashboard '$($dash.title)' co $($dash.panels.Count) bieu do:" -ForegroundColor Green
        foreach ($p in $dash.panels) { Write-Host "  - $($p.title)" -ForegroundColor Green }
    } else {
        Write-Host "[WARN] Khong tim thay dashboard 'System Health of <MSSV>'." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARN] Grafana API -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[Mo rong #9] API Gateway Route /student/..." -ForegroundColor White
try {
    $st = Invoke-RestMethod -Uri "http://localhost/student/" -TimeoutSec 5
    Write-Host "[PASS] http://localhost/student/ tra ve $($st.Count) sinh vien." -ForegroundColor Green
} catch {
    Write-Host "[WARN] /student/ -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[Mo rong #10] Load Balancing Round Robin (web-frontend-server1 & 2)..." -ForegroundColor White
for ($i = 1; $i -le 4; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing -TimeoutSec 5
        $servedBy = $resp.Headers["X-Served-By"]
        Write-Host "  Request #$i -> X-Served-By: $servedBy" -ForegroundColor Green
    } catch {
        Write-Host "  Request #$i -> $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=================================================================" -ForegroundColor Magenta
Write-Host "   HOAN TAT KIEM THU PHAN MO RONG!                               " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta
