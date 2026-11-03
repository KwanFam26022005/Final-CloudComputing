# =============================================================================
# TASK 5 - MINIO / STORAGE - HUNG 52300107
# Kiem tra HTML, avatar, PDF, link ky va quyen tai khoan doc.
# =============================================================================
param([switch]$ReadOnly)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$failures = 0
$python = if ($env:N07_PYTHON) {
    $env:N07_PYTHON
} else {
    Join-Path (Get-Location) "object-storage-server/.venv/Scripts/python.exe"
}
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  TASK 5 | STORAGE / MINIO | HUNG 52300107" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Kiem tra Docker, MinIO va SDK.
Write-Host "`n[PHAN 1] Docker / MinIO / SDK" -ForegroundColor Yellow
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[BLOCKED] Mo Docker Desktop/Engine." -ForegroundColor Red
    exit 2
}
if ((docker inspect object-storage-server --format '{{.State.Running}}') -ne "true") {
    Write-Host "[BLOCKED] Khoi chay MinIO." -ForegroundColor Red
    exit 2
}
if (!(Test-Path $python) -and !(Get-Command $python -ErrorAction SilentlyContinue)) {
    Write-Host "[BLOCKED] Tao venv va cai requirements-client.txt." -ForegroundColor Red
    exit 2
}
& $python -c "import minio"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[BLOCKED] Cai SDK theo requirements-client.txt." -ForegroundColor Red
    exit 2
}

# 2. Doi chieu du lieu va kiem tra link PDF.
Write-Host "`n[PHAN 2] Demo HTML / Avatar / PDF / Link ky" -ForegroundColor Yellow
& $python object-storage-server/verify_storage.py --all-pdfs
if ($LASTEXITCODE -ne 0) {
    $failures++
}
Write-Host "[UI] Tao bucket, upload/download tren Console; xac nhan PDF la bao cao that." -ForegroundColor Gray

# 3. Thu quyen doc va tu choi ghi/xoa/admin khi duoc chon.
Write-Host "`n[PHAN 3] Cai tien tai khoan chi doc" -ForegroundColor Yellow
if ($ReadOnly) {

    if (!$env:N07_MINIO_ACCESS_KEY -or !$env:N07_MINIO_SECRET_KEY) {
        Write-Host "[BLOCKED] Dat credential verifier theo README Storage." -ForegroundColor Red
        exit 2
    }
    & $python object-storage-server/verify_readonly.py
    if ($LASTEXITCODE -ne 0) {
        $failures++
    }

} else {
    Write-Host "[NOT RUN] Them -ReadOnly va credential de kiem quyen read-only." -ForegroundColor Gray
}
Write-Host "`nSUMMARY TASK5: FAIL=$failures" -ForegroundColor Cyan
if ($failures) {
    exit 1
}
exit 0
