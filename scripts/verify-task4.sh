#!/usr/bin/env bash
# =============================================================================
# TASK 4 - KEYCLOAK / AUTH - HUNG 52300107
# Kiem tra realm, token, App/Gateway, volume.
# =============================================================================

set -u
cd "$(dirname "$0")/.." || exit 2
failures=0

recreate=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --recreate-auth) recreate=true; shift ;;
        *) echo 'Usage: bash scripts/verify-task4.sh [--recreate-auth]'; exit 2 ;;
    esac
done
python_cmd="${N07_PYTHON:-python3}"
auth_url="${N07_AUTH_URL:-http://localhost:8081}"
app_url="${N07_APP_URL:-http://localhost:8085/secure}"
gateway_url="${N07_SECURE_URL:-http://localhost/api/secure}"
auth_container="${N07_AUTH_CONTAINER:-authentication-identity-server}"
printf '\n%s\n' '================================================================='
echo '  TASK 4 | AUTH / KEYCLOAK | HUNG 52300107'
printf '%s\n' '================================================================='

# 1. Kiem tra Docker va container Auth.
echo
echo '[PHAN 1] Docker / Keycloak'
docker info >/dev/null 2>&1 || {
    echo '[BLOCKED] Mo Docker Desktop/Engine.'
    exit 2
}
[ "$(docker inspect "$auth_container" --format '{{.State.Running}}' 2>/dev/null)" = true ] || {
    echo '[BLOCKED] Khoi chay Keycloak.'
    exit 2
}
command -v "$python_cmd" >/dev/null 2>&1 || {
    echo '[BLOCKED] Can Python3 cho cac verify Auth.'
    exit 2
}

# 2. Lay token va UserInfo cho sv01, sv02.
echo
echo '[PHAN 2] Realm / Client / Users / Token'
"$python_cmd" authentication-identity-server/verify_oidc.py --auth-url "$auth_url" || failures=$((failures+1))
echo '[UI] Dang nhap Admin Console, chon realm_52300107, kiem Users va flask-app.'

# 3. Goi API truc tiep va qua Gateway.
echo
echo '[PHAN 3] Token -> App -> Gateway'
echo
echo "--- APP TRUC TIEP: $app_url ---"
"$python_cmd" authentication-identity-server/verify_secure.py --auth-url "$auth_url" --app-url "$app_url" || failures=$((failures+1))
echo
echo "--- QUA GATEWAY: $gateway_url ---"
"$python_cmd" authentication-identity-server/verify_secure.py --auth-url "$auth_url" --app-url "$gateway_url" || failures=$((failures+1))

# 4. Kiem tra mount data va giu khoa ky sau recreate khi duoc chon.
echo
echo '[PHAN 4] Cai tien luu ben Keycloak'
mounts=$(docker inspect "$auth_container" --format '{{range .Mounts}}{{if eq .Destination "/opt/keycloak/data"}}{{.Type}} {{.RW}} {{.Name}}{{end}}{{end}}')
if printf '%s\n' "$mounts" | grep -q '^volume true '; then
    echo "[PASS] Data volume: $mounts"
else
    echo '[FAIL] Can named volume RW cho /opt/keycloak/data'
    failures=$((failures+1))
fi
if "$recreate"; then
    printf '%s\n' "$mounts" | grep -q '^volume true ' || exit 1
    [ "$auth_container" = authentication-identity-server ] || {
        echo '[FAIL] Recreate dung container mac dinh; kiem lai moi truong.'
        exit 1
    }
    echo '[INFO] Auth se gian doan ngan trong luc recreate.'
    before_id=$(docker inspect "$auth_container" --format '{{.Id}}')
    before_image=$(docker inspect "$auth_container" --format '{{.Image}}')
    before_mount="$mounts"
    realm=$(sed -n 's/^[[:space:]]*"realm"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' authentication-identity-server/import/realm-export.json | head -n 1)
    before_keys=$(curl -fsS "$auth_url/realms/$realm/protocol/openid-connect/certs") || exit 1
    docker compose up -d --no-deps --no-build --force-recreate authentication-identity-server || exit 1
    ready=false
    for attempt in $(seq 1 60); do
        if after_keys=$(curl -fsS "$auth_url/realms/$realm/protocol/openid-connect/certs" 2>/dev/null); then
            ready=true
            break
        fi
        sleep 1
    done
    after_id=$(docker inspect "$auth_container" --format '{{.Id}}')
    after_image=$(docker inspect "$auth_container" --format '{{.Image}}')
    after_mount=$(docker inspect "$auth_container" --format '{{range .Mounts}}{{if eq .Destination "/opt/keycloak/data"}}{{.Type}} {{.RW}} {{.Name}}{{end}}{{end}}')
    if "$ready" && [ "$before_id" != "$after_id" ] && [ "$before_image" = "$after_image" ] && [ "$before_mount" = "$after_mount" ] && [ "$before_keys" = "$after_keys" ]; then
        echo '[PASS] Container doi, image/volume/khoa ky giu nguyen.'
        "$python_cmd" authentication-identity-server/verify_oidc.py --auth-url "$auth_url" || failures=$((failures+1))
    else
        echo '[FAIL] Recreate/retention mismatch'
        failures=$((failures+1))
    fi
else
    echo '[NOT RUN] Them --recreate-auth de test giu du lieu sau recreate.'
fi

echo
echo "SUMMARY TASK4: FAIL=$failures"
echo 'JWT sai issuer/audience/het han va browser /auth/ can test rieng.'
[ "$failures" -eq 0 ]
