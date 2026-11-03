# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (PowerShell)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
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

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   MYMINICLOUD - KIEM THU TU DONG PHAN CO BAN (5.0 DIEM)         " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

function Check-Url($Name, $Url) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        Write-Host "[PASS] $Name -> HTTP $($resp.StatusCode) ($Url)" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] $Name -> Khong truy cap duoc ($Url): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n[1/10] Web Frontend Server (Port 8080)..." -ForegroundColor White
Check-Url "Web Home (/)" "http://localhost:8080/"
Check-Url "Web Blog (/blog/)" "http://localhost:8080/blog/"

Write-Host "`n[2/10] Application Backend Server (/hello)..." -ForegroundColor White
Check-Url "App Direct (8085/hello)" "http://localhost:8085/hello"
Check-Url "App via Proxy (/api/hello)" "http://localhost/api/hello"

Write-Host "`n[3/10] Relational Database Server (MariaDB minicloud.notes)..." -ForegroundColor White
docker exec relational-database-server mariadb -uroot -proot -e "USE minicloud; SELECT * FROM notes;"

Write-Host "`n[4/10] Authentication Identity Server (Keycloak Port 8081)..." -ForegroundColor White
Check-Url "Keycloak Console" "http://localhost:8081/"
Write-Host "[UI] Dang nhap Keycloak, kiem realm_52300107 / sv01 / sv02 / flask-app." -ForegroundColor Gray

Write-Host "`n[5/10] Object Storage Server (MinIO Console Port 9001)..." -ForegroundColor White
Check-Url "MinIO Console" "http://localhost:9001/"
Write-Host "[UI] MinIO Console: tao demo, upload index.html va tai lai de doi chieu." -ForegroundColor Gray

Write-Host "`n[6/10] Internal DNS Server (Bind9 Port 1053 - web-frontend-server.cloud.local)..." -ForegroundColor White
docker exec internal-dns-server dig "@127.0.0.1" web-frontend-server.cloud.local +short

Write-Host "`n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..." -ForegroundColor White
Check-Url "Node Exporter Metrics" "http://localhost:9100/metrics"
Check-Url "Prometheus Targets API" "http://localhost:9090/api/v1/targets"
Check-PromTargets "node"
try {
    $cpu = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query" -Body @{ query = "count(node_cpu_seconds_total)" } -TimeoutSec 5
    Write-Host "[PASS] node_cpu_seconds_total co $($cpu.data.result[0].value[1]) series." -ForegroundColor Green
} catch {
    Write-Host "[WARN] Query node_cpu_seconds_total -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[8/10] Monitoring Grafana Dashboard (Port 3000)..." -ForegroundColor White
Check-Url "Grafana UI" "http://localhost:3000/login"
try {
    $ds = Invoke-RestMethod -Uri "http://localhost:3000/api/datasources/uid/prometheus/health" -Headers $gfHeaders -TimeoutSec 5
    Write-Host "[PASS] Datasource Prometheus -> $($ds.message)" -ForegroundColor Green
    $nef = Invoke-RestMethod -Uri "http://localhost:3000/api/search?query=Node%20Exporter%20Full" -Headers $gfHeaders -TimeoutSec 5
    if ($nef) { Write-Host "[PASS] Dashboard '$($nef[0].title)' da co san." -ForegroundColor Green }
    else { Write-Host "[WARN] Chua co dashboard Node Exporter Full." -ForegroundColor Yellow }
} catch {
    Write-Host "[WARN] Grafana API -> $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..." -ForegroundColor White
Check-Url "Gateway Web (/)" "http://localhost/"
Check-Url "Gateway API (/api/hello)" "http://localhost/api/hello"
Check-Url "Gateway Auth (/auth/)" "http://localhost/auth/"

Write-Host "`n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..." -ForegroundColor White
$targets = @("web", "app-server", "db", "keycloak", "minio", "prometheus", "grafana", "dns-server")
foreach ($t in $targets) {
    docker exec object-storage-server ping -c 2 $t
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT KIEM THU PHAN CO BAN!                                " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
