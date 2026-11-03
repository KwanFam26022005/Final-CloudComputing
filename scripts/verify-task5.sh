#!/usr/bin/env bash
# =============================================================================
# TASK 5 - MINIO / STORAGE - HUNG 52300107
# Kiem tra HTML, avatar, PDF, link ky va quyen tai khoan doc.
# =============================================================================

set -u
cd "$(dirname "$0")/.." || exit 2
readonly_test=false
case "${1:-}" in '') ;; --readonly) readonly_test=true ;; *) echo 'Usage: bash scripts/verify-task5.sh [--readonly]'; exit 2 ;; esac
failures=0

python_cmd="${N07_PYTHON:-object-storage-server/.venv/bin/python}"
printf '\n%s\n' '================================================================='
echo '  TASK 5 | STORAGE / MINIO | HUNG 52300107'
printf '%s\n' '================================================================='

# 1. Kiem tra Docker, MinIO va SDK.
echo
echo '[PHAN 1] Docker / MinIO / SDK'
docker info >/dev/null 2>&1 || {
    echo '[BLOCKED] Mo Docker Desktop/Engine.'
    exit 2
}
[ "$(docker inspect object-storage-server --format '{{.State.Running}}' 2>/dev/null)" = true ] || {
    echo '[BLOCKED] Khoi chay MinIO.'
    exit 2
}
[ -x "$python_cmd" ] || command -v "$python_cmd" >/dev/null 2>&1 || {
    echo '[BLOCKED] Tao venv va cai object-storage-server/requirements-client.txt.'
    exit 2
}
"$python_cmd" -c 'import minio' >/dev/null 2>&1 || {
    echo '[BLOCKED] Cai SDK theo requirements-client.txt.'
    exit 2
}

# 2. Doi chieu du lieu va kiem tra link PDF.
echo
echo '[PHAN 2] Demo HTML / Avatar / PDF / Link ky'
"$python_cmd" object-storage-server/verify_storage.py --all-pdfs || failures=$((failures+1))
echo '[UI] Tao bucket, upload/download file tren Console; xac nhan PDF la bao cao that.'

# 3. Thu quyen doc va tu choi ghi/xoa/admin khi duoc chon.
echo
echo '[PHAN 3] Cai tien tai khoan chi doc'
if "$readonly_test"; then
    [ -n "${N07_MINIO_ACCESS_KEY:-}" ] && [ -n "${N07_MINIO_SECRET_KEY:-}" ] || {
        echo '[BLOCKED] Dat credential verifier theo README Storage.'
        exit 2
    }
    "$python_cmd" object-storage-server/verify_readonly.py || failures=$((failures+1))
else
    echo '[NOT RUN] Them --readonly va credential de kiem quyen read-only.'
fi
echo
echo "SUMMARY TASK5: FAIL=$failures"
[ "$failures" -eq 0 ]
