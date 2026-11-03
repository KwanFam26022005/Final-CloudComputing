# =============================================================================
# TASK 6 - BIND9 / DNS - HUNG 52300107
# Kiem tra cau hinh, ban ghi UDP/TCP va thong mang.
# =============================================================================
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$failures = 0
$dnsContainer = if ($env:N07_DNS_CONTAINER) {
    $env:N07_DNS_CONTAINER
} else {
    "internal-dns-server"
}
$storageContainer = if ($env:N07_STORAGE_CONTAINER) {
    $env:N07_STORAGE_CONTAINER
} else {
    "object-storage-server"
}
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  TASK 6 | DNS / BIND9 | HUNG 52300107" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Kiem tra Docker va cau hinh Bind9.
Write-Host "`n[PHAN 1] Docker / named-checkconf" -ForegroundColor Yellow
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[BLOCKED] Mo Docker Desktop/Engine." -ForegroundColor Red
    exit 2
}
docker exec $dnsContainer named-checkconf /etc/bind/named.conf
if ($LASTEXITCODE -ne 0) {
    exit 1
}

# 2. Kiem tra bon ban ghi qua UDP va TCP.
Write-Host "`n[PHAN 2] Ban ghi A / UDP / TCP" -ForegroundColor Yellow
$records = [ordered]@{
    "web-frontend-server"="10.10.10.10"
    "app-backend"="10.10.10.20"
    "minio"="10.10.10.30"
    "keycloak"="10.10.10.40"
}
foreach ($mode in @("+notcp", "+tcp")) {
    Write-Host "`n--- DNS $mode ---" -ForegroundColor Cyan

    foreach ($record in $records.GetEnumerator()) {

        $name = "$($record.Key).cloud.local"
        $ip = $record.Value
        $answer = (docker exec $dnsContainer dig "@127.0.0.1" $name A $mode +time=2 +tries=1 +noall +comments +answer) -join "`n"
        $ok = $LASTEXITCODE -eq 0 -and $answer -match 'status: NOERROR' -and $answer -match 'flags:.*\saa[\s;]' -and $answer -match (([regex]::Escape("$name.")) + '\s+\d+\s+IN\s+A\s+' + [regex]::Escape($ip) + '(\s|$)')
        if ($ok) {
            Write-Host "[PASS] $name $mode -> $ip" -ForegroundColor Green
        }
        else {
            Write-Host "[FAIL] $name $mode" -ForegroundColor Red; $failures++
        }

    }

}

# 3. Ping cac alias trong de.
Write-Host "`n[PHAN 3] Thong mang" -ForegroundColor Yellow
foreach ($target in @("web", "app-server", "db", "keycloak", "minio", "prometheus", "grafana", "dns-server")) {

    docker exec $storageContainer ping -c 2 -W 2 $target *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Ping $target" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] Ping $target; kiem container va cloud-net" -ForegroundColor Red; $failures++
    }

}
Write-Host "`nSUMMARY TASK6: FAIL=$failures" -ForegroundColor Cyan
if ($failures) {
    exit 1
}; exit 0
