#!/usr/bin/env bash
# =============================================================================
# TASK 6 - BIND9 / DNS - HUNG 52300107
# Kiem tra cau hinh, ban ghi UDP/TCP va thong mang.
# =============================================================================

set -u
cd "$(dirname "$0")/.." || exit 2
failures=0

dns_container="${N07_DNS_CONTAINER:-internal-dns-server}"
storage_container="${N07_STORAGE_CONTAINER:-object-storage-server}"
printf '\n%s\n' '================================================================='
echo '  TASK 6 | DNS / BIND9 | HUNG 52300107'
printf '%s\n' '================================================================='

# 1. Kiem tra Docker va cau hinh Bind9.
echo
echo '[PHAN 1] Docker / named-checkconf'
docker info >/dev/null 2>&1 || {
    echo '[BLOCKED] Mo Docker Desktop/Engine.'
    exit 2
}
docker exec "$dns_container" named-checkconf /etc/bind/named.conf || exit 1

# 2. Kiem tra bon ban ghi qua UDP va TCP.
echo
echo '[PHAN 2] Ban ghi A / UDP / TCP'
for mode in +notcp +tcp; do
    echo
    echo "--- DNS $mode ---"
    for record in web-frontend-server:10.10.10.10 app-backend:10.10.10.20 minio:10.10.10.30 keycloak:10.10.10.40; do
        name="${record%%:*}.cloud.local"
        ip="${record#*:}"
        answer=$(docker exec "$dns_container" dig @127.0.0.1 "$name" A "$mode" +time=2 +tries=1 +noall +comments +answer)
        if printf '%s\n' "$answer" | grep -q 'status: NOERROR' && printf '%s\n' "$answer" | grep -qE 'flags:.*[[:space:]]aa[[:space:];]' && printf '%s\n' "$answer" | awk -v n="$name." -v ip="$ip" '$1==n && $4=="A" && $5==ip {ok=1} END {exit !ok}'; then
            echo "[PASS] $name $mode -> $ip"
        else
            echo "[FAIL] $name $mode"
            failures=$((failures+1))
        fi
    done
done

# 3. Ping cac alias trong de.
echo
echo '[PHAN 3] Thong mang'
for target in web app-server db keycloak minio prometheus grafana dns-server; do
    if docker exec "$storage_container" ping -c 2 -W 2 "$target" >/dev/null 2>&1; then
        echo "[PASS] Ping $target";
    else
        echo "[FAIL] Ping $target; kiem container va cloud-net"
        failures=$((failures+1))
    fi
done
echo
echo "SUMMARY TASK6: FAIL=$failures"
[ "$failures" -eq 0 ]
