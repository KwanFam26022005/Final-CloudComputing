from flask import Flask, jsonify, request
import json
import os
import time
from datetime import datetime
import requests
import pymysql
from jose import jwt

app = Flask(__name__)

# =============================================================================
# CẤU HÌNH ĐƯỜNG DẪN & KẾT NỐI
# =============================================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STUDENTS_JSON_PATH = os.path.join(BASE_DIR, "students.json")

OIDC_INTERNAL_BASE = os.getenv("OIDC_INTERNAL_BASE", "http://authentication-identity-server:8080")
DEFAULT_ISSUER = os.getenv("OIDC_ISSUER", f"{OIDC_INTERNAL_BASE}/realms/master")
AUDIENCE = os.getenv("OIDC_AUDIENCE", "myapp")

DB_HOST = os.getenv("DB_HOST", "relational-database-server")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_NAME = os.getenv("DB_NAME", "studentdb")

_JWKS_CACHE = {}


def get_db_connection():
    """Tạo kết nối chuẩn tới cơ sở dữ liệu MariaDB với DictCursor."""
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=5,
    )


def validate_student_payload(payload: dict, partial: bool = False) -> tuple[bool, str]:
    """Kiểm tra tính hợp lệ của dữ liệu sinh viên đầu vào."""
    if not isinstance(payload, dict):
        return False, "Payload must be a JSON object"

    required_fields = ["student_id", "fullname", "dob", "major"]
    if not partial:
        for field in required_fields:
            if field not in payload or payload[field] is None or str(payload[field]).strip() == "":
                return False, f"Missing required field: '{field}'"

    if "student_id" in payload:
        sid = str(payload["student_id"]).strip()
        if not sid or len(sid) > 10:
            return False, "'student_id' must be non-empty and at most 10 characters"

    if "fullname" in payload:
        name = str(payload["fullname"]).strip()
        if not name or len(name) > 100:
            return False, "'fullname' must be non-empty and at most 100 characters"

    if "major" in payload:
        major = str(payload["major"]).strip()
        if not major or len(major) > 50:
            return False, "'major' must be non-empty and at most 50 characters"

    if "dob" in payload:
        dob_str = str(payload["dob"]).strip()
        try:
            datetime.strptime(dob_str, "%Y-%m-%d")
        except ValueError:
            return False, "'dob' must be in YYYY-MM-DD date format"

    return True, ""


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
# 0. ENDPOINT HEALTH CHECK
# =============================================================================
@app.get("/health")
def health():
    return jsonify(status="ok", service="application-backend-server")


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
    try:
        with open(STUDENTS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify(error=f"Error reading students.json: {str(e)}"), 500


# =============================================================================
# 4. ENDPOINTS CRUD VỚI DATABASE MARIADB (/students-db) - [Mở rộng #3]
# =============================================================================
@app.get("/students-db")
def get_students_db():
    """Lấy danh sách sinh viên trực tiếp từ bảng students trong CSDL studentdb."""
    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major FROM students ORDER BY id ASC;"
                )
                rows = cur.fetchall()
        return jsonify(source="MariaDB (studentdb.students)", count=len(rows), students=rows)
    except Exception as e:
        return jsonify(error=f"Database connection error: {str(e)}"), 500


@app.post("/students-db")
def create_student_db():
    """Tạo mới một sinh viên trong bảng students (CREATE)."""
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify(error="Invalid or missing JSON request body"), 400

    is_valid, err_msg = validate_student_payload(payload, partial=False)
    if not is_valid:
        return jsonify(error=err_msg), 400

    student_id = str(payload["student_id"]).strip()
    fullname = str(payload["fullname"]).strip()
    dob = str(payload["dob"]).strip()
    major = str(payload["major"]).strip()

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO students (student_id, fullname, dob, major) VALUES (%s, %s, %s, %s);",
                    (student_id, fullname, dob, major),
                )
                conn.commit()
                new_id = cur.lastrowid
        return (
            jsonify(
                message="Student created successfully",
                student={
                    "id": new_id,
                    "student_id": student_id,
                    "fullname": fullname,
                    "dob": dob,
                    "major": major,
                },
            ),
            201,
        )
    except pymysql.err.IntegrityError as e:
        if e.args and e.args[0] == 1062:
            return jsonify(error=f"Student ID '{student_id}' already exists"), 409
        return jsonify(error=f"Database integrity error: {str(e)}"), 400
    except Exception as e:
        return jsonify(error=f"Database error: {str(e)}"), 500


@app.put("/students-db/<student_id>")
def update_student_db(student_id: str):
    """Cập nhật thông tin sinh viên theo student_id (UPDATE)."""
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify(error="Invalid or missing JSON request body"), 400

    is_valid, err_msg = validate_student_payload(payload, partial=True)
    if not is_valid:
        return jsonify(error=err_msg), 400

    fields_to_update = []
    values = []
    for col in ["fullname", "dob", "major"]:
        if col in payload:
            fields_to_update.append(f"{col} = %s")
            values.append(str(payload[col]).strip())

    if not fields_to_update:
        return jsonify(error="No valid fields provided to update"), 400

    values.append(student_id)
    sql = f"UPDATE students SET {', '.join(fields_to_update)} WHERE student_id = %s;"

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cur:
                cur.execute(sql, tuple(values))
                conn.commit()
                if cur.rowcount == 0:
                    # Kiểm tra xem bản ghi có thực sự tồn tại không
                    cur.execute("SELECT id FROM students WHERE student_id = %s;", (student_id,))
                    if not cur.fetchone():
                        return jsonify(error=f"Student '{student_id}' not found"), 404

                cur.execute(
                    "SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major FROM students WHERE student_id = %s;",
                    (student_id,),
                )
                updated_student = cur.fetchone()

        return jsonify(message="Student updated successfully", student=updated_student), 200
    except pymysql.err.IntegrityError as e:
        return jsonify(error=f"Database integrity error: {str(e)}"), 400
    except Exception as e:
        return jsonify(error=f"Database error: {str(e)}"), 500


@app.delete("/students-db/<student_id>")
def delete_student_db(student_id: str):
    """Xóa một sinh viên theo student_id (DELETE)."""
    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cur:
                cur.execute("DELETE FROM students WHERE student_id = %s;", (student_id,))
                conn.commit()
                if cur.rowcount == 0:
                    return jsonify(error=f"Student '{student_id}' not found"), 404
        return jsonify(message="Student deleted successfully", student_id=student_id), 200
    except Exception as e:
        return jsonify(error=f"Database error: {str(e)}"), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
