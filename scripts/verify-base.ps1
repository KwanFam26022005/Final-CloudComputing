# =============================================================================
# MYMINICLOUD - AUTOMATED BASE VERIFICATION SCRIPT (PowerShell)
# Kiểm thử tự động 10 hạng mục Cơ bản (5.0 điểm)
# =============================================================================
$ErrorActionPreference = "Continue"

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

Write-Host "`n[5/10] Object Storage Server (MinIO Console Port 9001)..." -ForegroundColor White
Check-Url "MinIO Console" "http://localhost:9001/"

Write-Host "`n[6/10] Internal DNS Server (Bind9 Port 1053 - web-frontend-server.cloud.local)..." -ForegroundColor White
docker run --rm --network cloud-net internetsystemsconsortium/bind9:9.18 dig @dns-server web-frontend-server.cloud.local +short

Write-Host "`n[7/10] Monitoring Prometheus & Node Exporter (Port 9090 & 9100)..." -ForegroundColor White
Check-Url "Node Exporter Metrics" "http://localhost:9100/metrics"
Check-Url "Prometheus Targets API" "http://localhost:9090/api/v1/targets"

Write-Host "`n[8/10] Monitoring Grafana Dashboard (Port 3000)..." -ForegroundColor White
Check-Url "Grafana UI" "http://localhost:3000/login"

Write-Host "`n[9/10] API Gateway Reverse Proxy (Port 80: /, /api/hello, /auth/)..." -ForegroundColor White
Check-Url "Gateway Web (/)" "http://localhost/"
Check-Url "Gateway API (/api/hello)" "http://localhost/api/hello"
Check-Url "Gateway Auth (/auth/)" "http://localhost/auth/"

Write-Host "`n[10/10] Kiem tra thong mang noi bo (Ping tren cloud-net)..." -ForegroundColor White
$targets = @("web", "app-server", "db", "keycloak", "minio", "prometheus", "grafana", "dns-server")
foreach ($t in $targets) {
    docker exec api-gateway-proxy-server ping -c 2 $t
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT KIEM THU PHAN CO BAN!                                " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
