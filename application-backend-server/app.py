from flask import Flask, jsonify, request
import json
import os
import time
import requests
import pymysql
from jose import jwt

app = Flask(__name__)

# =============================================================================
# CẤU HÌNH KẾT NỐI KEYCLOAK (OIDC) & MARIADB
# =============================================================================
OIDC_INTERNAL_BASE = os.getenv("OIDC_INTERNAL_BASE", "http://authentication-identity-server:8080")
DEFAULT_ISSUER = os.getenv("OIDC_ISSUER", f"{OIDC_INTERNAL_BASE}/realms/master")
AUDIENCE = os.getenv("OIDC_AUDIENCE", "myapp")

DB_HOST = os.getenv("DB_HOST", "relational-database-server")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_NAME = os.getenv("DB_NAME", "studentdb")

_JWKS_CACHE = {}


def get_jwks_for_realm(realm_name: str):
    """Tải và cache bộ khóa công khai JWKS từ Keycloak qua mạng nội bộ cloud-net."""
    now = time.time()
    cached = _JWKS_CACHE.get(realm_name)
    if not cached or (now - cached["ts"] > 600):
        jwks_url = f"{OIDC_INTERNAL_BASE}/realms/{realm_name}/protocol/openid-connect/certs"
        resp = requests.get(jwks_url, timeout=5)
        resp.raise_for_status()
        _JWKS_CACHE[realm_name] = {"jwks": resp.json(), "ts": now}
    return _JWKS_CACHE[realm_name]["jwks"]


def extract_realm_from_token(token: str) -> str:
    """Trích xuất tên realm từ claim 'iss' trong JWT (hỗ trợ cả master và realm_<mssv>)."""
    try:
        unverified_claims = jwt.get_unverified_claims(token)
        iss = unverified_claims.get("iss", "")
        if "/realms/" in iss:
            return iss.split("/realms/", 1)[1].strip("/")
    except Exception:
        pass
    return "master"


# =============================================================================
# 1. ENDPOINT CƠ BẢN (/hello) - [Cơ bản #2]
# =============================================================================
@app.get("/hello")
def hello():
    return jsonify(message="Hello from App Server!")


# =============================================================================
# 2. ENDPOINT BẢO MẬT OIDC (/secure) - [Cơ bản #2 & Mở rộng #4]
# =============================================================================
@app.get("/secure")
def secure():
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify(error="Missing Bearer token"), 401

    token = auth.split(" ", 1)[1].strip()
    try:
        realm_name = extract_realm_from_token(token)
        jwks = get_jwks_for_realm(realm_name)
        payload = jwt.decode(
            token,
            jwks,
            algorithms=["RS256"],
            options={"verify_aud": False, "verify_iss": False},
        )
        return jsonify(
            message="Secure resource OK",
            preferred_username=payload.get("preferred_username"),
            realm=realm_name,
            client_id=payload.get("azp"),
        )
    except Exception as e:
        return jsonify(error=str(e)), 401


# =============================================================================
# 3. ENDPOINT ĐỌC DANH SÁCH SINH VIÊN TỪ FILE JSON (/student) - [Mở rộng #2]
# =============================================================================
@app.get("/student")
def student():
    # TODO [Thành viên 2 - Mở rộng #2]: Có thể cập nhật tên thật các thành viên trong students.json
    with open("students.json", "r", encoding="utf-8") as f:
        data = json.load(f)
    return jsonify(data)


# =============================================================================
# 4. ENDPOINT ĐỌC SINH VIÊN TỪ DATABASE MARIADB (/students-db) - [Mở rộng #3]
# =============================================================================
@app.get("/students-db")
def students_db():
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=5,
        )
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major FROM students ORDER BY id ASC;"
                )
                rows = cur.fetchall()
        return jsonify(source="MariaDB (studentdb.students)", count=len(rows), students=rows)
    except Exception as e:
        return jsonify(error=f"Database connection error: {str(e)}"), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
