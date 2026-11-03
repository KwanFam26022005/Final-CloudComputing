# =============================================================================
# TASK 4 - KEYCLOAK / AUTH - HUNG 52300107
# Kiem tra realm, token, App/Gateway, volume.
# =============================================================================
param([switch]$RecreateAuth)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$failures = 0
$python = if ($env:N07_PYTHON) {
    $env:N07_PYTHON
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    "python3"
} else {
    "python"
}
$authUrl = if ($env:N07_AUTH_URL) {
    $env:N07_AUTH_URL.TrimEnd('/')
} else {
    "http://localhost:8081"
}
$appUrl = if ($env:N07_APP_URL) {
    $env:N07_APP_URL
} else {
    "http://localhost:8085/secure"
}
$secureUrl = if ($env:N07_SECURE_URL) {
    $env:N07_SECURE_URL
} else {
    "http://localhost/api/secure"
}
$authContainer = if ($env:N07_AUTH_CONTAINER) {
    $env:N07_AUTH_CONTAINER
} else {
    "authentication-identity-server"
}
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  TASK 4 | AUTH / KEYCLOAK | HUNG 52300107" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Kiem tra Docker va container Auth.
Write-Host "`n[PHAN 1] Docker / Keycloak" -ForegroundColor Yellow
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[BLOCKED] Mo Docker Desktop/Engine." -ForegroundColor Red
    exit 2
}
$running = docker inspect $authContainer --format '{{.State.Running}}' 2>$null
if ($running -ne "true") {
    Write-Host "[BLOCKED] Khoi chay Keycloak." -ForegroundColor Red
    exit 2
}

# 2. Lay token va UserInfo cho sv01, sv02.
if (!(Get-Command $python -ErrorAction SilentlyContinue)) {
    Write-Host "[BLOCKED] Can Python3 cho verify Auth." -ForegroundColor Red
    exit 2
}
Write-Host "`n[PHAN 2] Realm / Client / Users / Token" -ForegroundColor Yellow
& $python authentication-identity-server/verify_oidc.py --auth-url $authUrl
if ($LASTEXITCODE -ne 0) {
    $failures++
}
Write-Host "[UI] Dang nhap Admin Console, chon realm_52300107, kiem Users va flask-app." -ForegroundColor Gray

# 3. Goi API truc tiep va qua Gateway.
Write-Host "`n[PHAN 3] Token -> App -> Gateway" -ForegroundColor Yellow
foreach ($url in @($appUrl, $secureUrl)) {
    $label = if ($url -eq $appUrl) { "APP TRUC TIEP" } else { "QUA GATEWAY" }
    Write-Host "`n--- ${label}: $url ---" -ForegroundColor Cyan

    & $python authentication-identity-server/verify_secure.py --auth-url $authUrl --app-url $url
    if ($LASTEXITCODE -ne 0) {
        $failures++
    }

}

# 4. Kiem tra mount data va giu khoa ky sau recreate khi duoc chon.
Write-Host "`n[PHAN 4] Cai tien luu ben Keycloak" -ForegroundColor Yellow
$info = (docker inspect $authContainer | ConvertFrom-Json)[0]
$mount = @($info.Mounts | Where-Object {
    $_.Destination -eq "/opt/keycloak/data"
})
if ($mount.Count -eq 1 -and $mount[0].Type -eq "volume" -and $mount[0].RW) {

    Write-Host "[PASS] Data volume: $($mount[0].Name)" -ForegroundColor Green

} else {
    Write-Host "[FAIL] Can named volume RW." -ForegroundColor Red; $failures++
}
if ($RecreateAuth) {

    if ($authContainer -ne "authentication-identity-server" -or $mount.Count -ne 1 -or $mount[0].Type -ne "volume") {
        throw "Kiem tra container/volume truoc recreate"
    }
    Write-Host "[INFO] Auth se gian doan ngan trong luc recreate." -ForegroundColor Yellow
    $realm = (Get-Content authentication-identity-server/import/realm-export.json -Raw | ConvertFrom-Json).realm
    $keysUrl = "$authUrl/realms/$realm/protocol/openid-connect/certs"
    $beforeKeys = (Invoke-WebRequest $keysUrl -UseBasicParsing).Content
    docker compose up -d --no-deps --no-build --force-recreate authentication-identity-server
    if ($LASTEXITCODE -ne 0) {
        exit 1
    }
    $ready = $false
    for ($attempt=0; $attempt -lt 60; $attempt++) {

        try {
            $afterKeys = (Invoke-WebRequest $keysUrl -UseBasicParsing -TimeoutSec 3).Content; $ready=$true; break
        } catch {
            Start-Sleep -Seconds 1
        }

    }
    $after = (docker inspect $authContainer | ConvertFrom-Json)[0]
    $afterMount = @($after.Mounts | Where-Object {
        $_.Destination -eq "/opt/keycloak/data"
    })
    if ($ready -and $info.Id -ne $after.Id -and $info.Image -eq $after.Image -and $afterMount.Count -eq 1 -and $afterMount[0].Name -eq $mount[0].Name -and $beforeKeys -eq $afterKeys) {

        Write-Host "[PASS] Container doi, image/volume/khoa ky giu nguyen." -ForegroundColor Green
        & $python authentication-identity-server/verify_oidc.py --auth-url $authUrl
        if ($LASTEXITCODE -ne 0) {
            $failures++
        }

    } else {
        Write-Host "[FAIL] Recreate/retention mismatch." -ForegroundColor Red; $failures++
    }

} else {
    Write-Host "[NOT RUN] Them -RecreateAuth de test giu du lieu sau recreate." -ForegroundColor Gray
}

Write-Host "`nSUMMARY TASK4: FAIL=$failures" -ForegroundColor Cyan
Write-Host "JWT sai issuer/audience/het han va browser /auth/ can test rieng." -ForegroundColor Gray
if ($failures) {
    exit 1
}; exit 0
