# =============================================================================
# MYMINICLOUD - AUTOMATED EXTENDED VERIFICATION SCRIPT (PowerShell)
# Kiểm thử tự động 10 hạng mục Mở rộng (5.0 điểm)
# Cuối script in "SUMMARY: PASS=x FAIL=y" và exit 1 nếu có FAIL.
# =============================================================================
$ErrorActionPreference = "Continue"

$gfUser = if ($env:GF_SECURITY_ADMIN_USER) { $env:GF_SECURITY_ADMIN_USER } else { "admin" }
$gfPass = if ($env:GF_SECURITY_ADMIN_PASSWORD) { $env:GF_SECURITY_ADMIN_PASSWORD } else { "admin" }
$gfHeaders = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${gfUser}:${gfPass}")) }
$dbPass = if ($env:MARIADB_ROOT_PASSWORD) { $env:MARIADB_ROOT_PASSWORD } else { "root" }

# Bộ đếm kết quả
$script:PassCount = 0
$script:FailCount = 0
function Pass($Msg) { $script:PassCount++; Write-Host "[PASS] $Msg" -ForegroundColor Green }
function Fail($Msg) { $script:FailCount++; Write-Host "[FAIL] $Msg" -ForegroundColor Red }

# In trạng thái UP/DOWN của từng target trong 1 job, dựa trên metric 'up' do Prometheus tự sinh
# Phải có đủ $Expected target và tất cả đều UP.
function Check-PromTargets($Job, $Expected = 1) {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query" -Body @{ query = "up{job=`"$Job`"}" } -TimeoutSec 5
        $results = @($r.data.result)
        if ($results.Count -lt $Expected) {
            Fail "job=$Job chi co $($results.Count)/$Expected target (Prometheus chua chay hoac chua scrape)."
        }
        foreach ($t in $results) {
            if ($t.value[1] -eq "1") {
                Pass "job=$Job $($t.metric.instance) -> UP"
            } else {
                Fail "job=$Job $($t.metric.instance) -> DOWN"
            }
        }
    } catch {
        Fail "Prometheus API -> $($_.Exception.Message)"
    }
}

Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "   MYMINICLOUD - KIEM THU TU DONG 10 MUC MO RONG (5.0 DIEM)      " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

Write-Host "`n[Mo rong #1] Web Frontend Blog 3 bai viet HTML..." -ForegroundColor White
foreach ($b in @("blog1.html", "blog2.html", "blog3.html")) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8080/blog/$b" -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { Pass "/blog/$b -> HTTP $($r.StatusCode)" }
        else { Fail "/blog/$b -> HTTP $($r.StatusCode)" }
    } catch {
        Fail "/blog/$b -> $($_.Exception.Message)"
    }
}

Write-Host "`n[Mo rong #2] Backend API /student (tu students.json)..." -ForegroundColor White
try {
    $s = Invoke-RestMethod -Uri "http://localhost/api/student" -TimeoutSec 5
    $n = @($s).Count
    if ($n -eq 5) { Pass "/api/student tra ve $n sinh vien." }
    else { Fail "/api/student tra ve $n sinh vien (ky vong 5)." }
} catch {
    Fail "/api/student -> $($_.Exception.Message)"
}

Write-Host "`n[Mo rong #3] Database studentdb.students & API /api/students-db..." -ForegroundColor White
docker exec relational-database-server mariadb -uroot "-p$dbPass" -e "USE studentdb; SELECT * FROM students;"
if ($LASTEXITCODE -eq 0) { Pass "studentdb.students truy van duoc" } else { Fail "studentdb.students khong truy van duoc (exit=$LASTEXITCODE)" }
try {
    $sdb = Invoke-RestMethod -Uri "http://localhost/api/students-db" -TimeoutSec 5
    if ([int]$sdb.count -ge 3) { Pass "/api/students-db tra ve $($sdb.count) ban ghi tu MariaDB." }
    else { Fail "/api/students-db tra ve $($sdb.count) ban ghi (ky vong >= 3)." }
} catch {
    Fail "/api/students-db -> $($_.Exception.Message)"
}

Write-Host "`n[Mo rong #4] Keycloak OIDC Realm realm_52300107 + Token + /api/secure..." -ForegroundColor White
try {
    $tokenResp = Invoke-RestMethod -Method Post -Uri "http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body "client_id=flask-app&username=sv01&password=sv01pass&grant_type=password"
    $token = $tokenResp.access_token
    $secResp = Invoke-RestMethod -Uri "http://localhost/api/secure" -Headers @{ Authorization = "Bearer $token" }
    if ($secResp.preferred_username -eq "sv01") {
        Pass "OIDC /api/secure OK -> User: $($secResp.preferred_username), Realm: $($secResp.realm)"
    } else {
        Fail "OIDC /api/secure -> preferred_username='$($secResp.preferred_username)' (ky vong sv01)"
    }
} catch {
    Fail "OIDC /api/secure -> $($_.Exception.Message)"
}

# Mo rong 5: kiem tra anh public va minh chung PDF tren Console.
Write-Host "`n[Mo rong #5] MinIO avatar va PDF bao cao..." -ForegroundColor White
try {
    $m3Avatar = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:9000/profile-pics/avatar.jpg" -TimeoutSec 10 -ErrorAction Stop
    if ($m3Avatar.StatusCode -eq 200) { Pass "Avatar HTTP $($m3Avatar.StatusCode)" }
    else { Fail "Avatar HTTP $($m3Avatar.StatusCode)" }
} catch { Fail "Avatar chua doc public duoc." }
Write-Host "[UI] Mo avatar an danh; trong documents kiem PDF bao cao, tai ve va mo noi dung." -ForegroundColor Gray

Write-Host "`n[Mo rong #6] Internal DNS (app-backend, minio, keycloak.cloud.local)..." -ForegroundColor White
$dnsExpect = [ordered]@{
    "web-frontend-server.cloud.local" = "10.10.10.10"
    "app-backend.cloud.local"         = "10.10.10.20"
    "minio.cloud.local"               = "10.10.10.30"
    "keycloak.cloud.local"            = "10.10.10.40"
}
foreach ($name in $dnsExpect.Keys) {
    $ans = (docker exec internal-dns-server dig "@127.0.0.1" $name +short 2>&1 | Out-String).Trim()
    Write-Host "  $name -> $ans"
    if ($ans -eq $dnsExpect[$name]) { Pass "$name -> $ans" }
    else { Fail "$name -> '$ans' (ky vong $($dnsExpect[$name]))" }
}

Write-Host "`n[Mo rong #7] Prometheus Scrape Target 'web' (web-frontend-server:80)..." -ForegroundColor White
Check-PromTargets "web" 2

Write-Host "`n[Mo rong #8] Grafana Dashboard 'System Health of <MSSV>' (3 bieu do)..." -ForegroundColor White
try {
    $found = Invoke-RestMethod -Uri "http://localhost:3000/api/search?query=System%20Health%20of" -Headers $gfHeaders -TimeoutSec 5
    if ($found) {
        $dash = (Invoke-RestMethod -Uri "http://localhost:3000/api/dashboards/uid/$($found[0].uid)" -Headers $gfHeaders -TimeoutSec 5).dashboard
        $pc = @($dash.panels).Count
        if ($pc -ge 3) { Pass "Dashboard '$($dash.title)' co $pc bieu do:" }
        else { Fail "Dashboard '$($dash.title)' chi co $pc bieu do (ky vong >= 3):" }
        foreach ($p in $dash.panels) { Write-Host "  - $($p.title)" -ForegroundColor Green }
    } else {
        Fail "Khong tim thay dashboard 'System Health of <MSSV>'."
    }
} catch {
    Fail "Grafana API -> $($_.Exception.Message)"
}

Write-Host "`n[Mo rong #9] API Gateway Route /student/..." -ForegroundColor White
try {
    $st = Invoke-RestMethod -Uri "http://localhost/student/" -TimeoutSec 5
    $n = @($st).Count
    if ($n -eq 5) { Pass "http://localhost/student/ tra ve $n sinh vien." }
    else { Fail "http://localhost/student/ tra ve $n sinh vien (ky vong 5)." }
} catch {
    Fail "/student/ -> $($_.Exception.Message)"
}

Write-Host "`n[Mo rong #10] Load Balancing Round Robin (web-frontend-server1 & 2)..." -ForegroundColor White
$seen = @{}
for ($i = 1; $i -le 6; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing -TimeoutSec 5
        $servedBy = "$($resp.Headers["X-Served-By"])"
        $seen[$servedBy] = $true
        Write-Host "  Request #$i -> X-Served-By: $servedBy" -ForegroundColor Green
    } catch {
        Write-Host "  Request #$i -> $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
if ($seen.Keys -match "web-frontend-server1" -and $seen.Keys -match "web-frontend-server2") {
    Pass "Round Robin: thay ca web-frontend-server1 va web-frontend-server2"
} else {
    Fail "Round Robin: chi thay [$($seen.Keys -join ', ')] (ky vong ca server1 va server2)"
}

Write-Host "`n=================================================================" -ForegroundColor Magenta
Write-Host "   HOAN TAT KIEM THU PHAN MO RONG!                               " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "SUMMARY: PASS=$($script:PassCount) FAIL=$($script:FailCount)"
if ($script:FailCount -gt 0) { exit 1 }
exit 0
