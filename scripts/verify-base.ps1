# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (PowerShell)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
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

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   MYMINICLOUD - KIEM THU TU DONG PHAN CO BAN (5.0 DIEM)         " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Kiem tra HTTP 200 va (neu co) noi dung phai chua chuoi $Contains
function Check-Url($Name, $Url, $Contains = $null) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -ne 200) {
            Fail "$Name -> HTTP $($resp.StatusCode) ($Url)"
        } elseif ($Contains -and ("$($resp.Content)" -notlike "*$Contains*")) {
            Fail "$Name -> HTTP 200 nhung thieu noi dung '$Contains' ($Url)"
        } elseif ($Contains) {
            Pass "$Name -> HTTP $($resp.StatusCode), co '$Contains' ($Url)"
        } else {
            Pass "$Name -> HTTP $($resp.StatusCode) ($Url)"
        }
    } catch {
        Fail "$Name -> Khong truy cap duoc ($Url): $($_.Exception.Message)"
    }
}

# Kiem tra redirect va trang dich Keycloak, khong chap nhan redirect toi 404.
function Check-Redirect($Name, $Url) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction Stop
        Fail "$Name -> HTTP $($resp.StatusCode), ky vong redirect 3xx ($Url)"
    } catch {
        $r = $_.Exception.Response
        $code = if ($r) { [int]$r.StatusCode } else { 0 }
        if ($code -ge 300 -and $code -lt 400) {
            $loc = "$($r.Headers.Location)"
            if (-not $loc) { try { $loc = ($r.Headers | Where-Object { $_.Key -eq 'Location' }).Value -join '' } catch {} }
            try {
                $final = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -MaximumRedirection 10 -ErrorAction Stop
                if ($final.StatusCode -eq 200 -and "$($final.Content)" -match '(?i)keycloak') {
                    Pass "$Name -> HTTP $code, Location: $loc; final HTTP 200 Keycloak ($Url)"
                } else {
                    Fail "$Name -> Redirect khong den trang Keycloak HTTP 200 ($Url)"
                }
            } catch {
                Fail "$Name -> Trang dich redirect loi: $($_.Exception.Message)"
            }
        } else {
            Fail "$Name -> Khong co redirect 3xx ($Url): $($_.Exception.Message)"
        }
    }
}

Write-Host "`n[1/10] Web Frontend Server (Port 8080)..." -ForegroundColor White
Check-Url "Web Home (/)" "http://localhost:8080/"
Check-Url "Web Blog (/blog/)" "http://localhost:8080/blog/"

Write-Host "`n[2/10] Application Backend Server (/hello)..." -ForegroundColor White
Check-Url "App Direct (8085/hello)" "http://localhost:8085/hello" "Hello from App Server!"
Check-Url "App via Proxy (/api/hello)" "http://localhost/api/hello" "Hello from App Server!"

Write-Host "`n[3/10] Relational Database Server (MariaDB minicloud.notes)..." -ForegroundColor White
$notes = (docker exec relational-database-server mariadb -uroot "-p$dbPass" -e "USE minicloud; SELECT * FROM notes;" 2>&1 | Out-String)
Write-Host $notes
if ($LASTEXITCODE -eq 0 -and $notes -like "*Hello from MariaDB!*") {
    Pass "minicloud.notes co 'Hello from MariaDB!'"
} else {
    Fail "minicloud.notes khong co 'Hello from MariaDB!' (exit=$LASTEXITCODE)"
}

Write-Host "`n[4/10] Authentication Identity Server (Keycloak Port 8081)..." -ForegroundColor White
Check-Url "Keycloak Console" "http://localhost:8081/"
Write-Host "[UI] Dang nhap Keycloak, kiem realm_52300107 / sv01 / sv02 / flask-app." -ForegroundColor Gray

Write-Host "`n[5/10] Object Storage Server (MinIO Console Port 9001)..." -ForegroundColor White
Check-Url "MinIO Console" "http://localhost:9001/"
Write-Host "[UI] MinIO Console: tao demo, upload index.html va tai lai de doi chieu." -ForegroundColor Gray

Write-Host "`n[6/10] Internal DNS Server (Bind9 Port 1053 - web-frontend-server.cloud.local)..." -ForegroundColor White
$dns = (docker exec internal-dns-server dig "@127.0.0.1" web-frontend-server.cloud.local +short 2>&1 | Out-String).Trim()
Write-Host $dns
if ($dns -eq "10.10.10.10") {
    Pass "web-frontend-server.cloud.local -> 10.10.10.10"
} else {
    Fail "web-frontend-server.cloud.local -> '$dns' (ky vong 10.10.10.10)"
}

Write-Host "`n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..." -ForegroundColor White
Check-Url "Node Exporter Metrics" "http://localhost:9100/metrics"
Check-Url "Prometheus Targets API" "http://localhost:9090/api/v1/targets"
Check-PromTargets "node" 1
try {
    $cpu = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query" -Body @{ query = "count(node_cpu_seconds_total)" } -TimeoutSec 5
    $cpuN = if ($cpu.data.result) { [int]$cpu.data.result[0].value[1] } else { 0 }
    if ($cpuN -gt 0) { Pass "node_cpu_seconds_total co $cpuN series." }
    else { Fail "node_cpu_seconds_total khong co du lieu." }
} catch {
    Fail "Query node_cpu_seconds_total -> $($_.Exception.Message)"
}

Write-Host "`n[8/10] Monitoring Grafana Dashboard (Port 3000)..." -ForegroundColor White
Check-Url "Grafana UI" "http://localhost:3000/login"
try {
    $ds = Invoke-RestMethod -Uri "http://localhost:3000/api/datasources/uid/prometheus/health" -Headers $gfHeaders -TimeoutSec 5
    if ($ds.status -eq "OK") { Pass "Datasource Prometheus -> $($ds.message)" }
    else { Fail "Datasource Prometheus -> $($ds.status): $($ds.message)" }
    $nef = Invoke-RestMethod -Uri "http://localhost:3000/api/search?query=Node%20Exporter%20Full" -Headers $gfHeaders -TimeoutSec 5
    if ($nef) { Pass "Dashboard '$($nef[0].title)' da co san." }
    else { Fail "Chua co dashboard Node Exporter Full." }
} catch {
    Fail "Grafana API -> $($_.Exception.Message)"
}

Write-Host "`n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..." -ForegroundColor White
Check-Url "Gateway Web (/)" "http://localhost/"
Check-Url "Gateway API (/api/hello)" "http://localhost/api/hello" "Hello from App Server!"
Check-Redirect "Gateway Auth (/auth/)" "http://localhost/auth/"

Write-Host "`n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..." -ForegroundColor White
$targets = @("web", "app-server", "db", "keycloak", "minio", "prometheus", "grafana", "dns-server")
foreach ($t in $targets) {
    docker exec object-storage-server ping -c 2 $t
    if ($LASTEXITCODE -eq 0) { Pass "ping $t" } else { Fail "ping $t (exit=$LASTEXITCODE)" }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT KIEM THU PHAN CO BAN!                                " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "SUMMARY: PASS=$($script:PassCount) FAIL=$($script:FailCount)"
if ($script:FailCount -gt 0) { exit 1 }
exit 0
