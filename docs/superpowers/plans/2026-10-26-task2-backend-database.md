# Task 2 (Backend & Data Lead) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện trọn gói phần việc của Thành viên 2 (Backend & Data Lead - 2.0/10.0 điểm) gồm Flask Backend API (`/hello`, `/secure`, `/student`, CRUD `/students-db`), MariaDB (`minicloud.notes`, `studentdb.students`, script `crud_practice.sql`), bộ unit tests & script kiểm thử tự động, và tài liệu Báo cáo Chương 3 & 4 trên nhánh riêng `feat/m2-backend-data-lead`.

**Architecture:** Tầng ứng dụng Flask (`application-backend-server` cổng `8085:8081`) xử lý các yêu cầu REST API, đọc dữ liệu tĩnh từ `students.json` (theo đường dẫn tuyệt đối của module), xác thực JWT RS256 với Keycloak (`authentication-identity-server:8080`) và kết nối trực tiếp tới MariaDB 11 (`relational-database-server:3306`) qua `PyMySQL` để thực hiện truy vấn & CRUD trên CSDL `studentdb`. Toàn bộ thay đổi được cô lập và quản lý trên nhánh Git `feat/m2-backend-data-lead`.

**Tech Stack:** Python 3.11, Flask 3.0.0, PyMySQL 1.1.1, python-jose[cryptography] 3.3.0, requests 2.31.0, unittest (Python standard library), MariaDB 11 SQL, PowerShell & Bash, Docker & Docker Compose.

**Spec:** `docs/superpowers/specs/2026-10-26-task2-backend-database-design.md`

## Global Constraints

- Mọi thao tác commit và push bắt buộc thực hiện trên nhánh **`feat/m2-backend-data-lead`**; tuyệt đối **không** commit hay push trực tiếp lên nhánh `main`.
- Chỉ tạo/sửa file trong phạm vi của Thành viên 2 (`application-backend-server/`, `relational-database-server/`, `scripts/verify-task2.*`, `docs/member2-backend-db-report.md`, `docs/superpowers/`). Không sửa `docker-compose.yml` hay thư mục của thành viên khác.
- Giữ nguyên cấu hình cổng (`8085:8081` cho Flask, `3306:3306` cho MariaDB) và các biến môi trường `OIDC_INTERNAL_BASE`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.
- Không thêm thư viện bên ngoài mới vào `requirements.txt` (chỉ sử dụng `flask`, `requests`, `python-jose[cryptography]`, `pymysql` và thư viện chuẩn Python).
- Commit message bắt buộc tuân thủ chuẩn Conventional Commits (`feat(app): ...`, `feat(db): ...`, `test(app): ...`, `docs(report): ...`).

## Review Focus

- Gọi `GET /student` khi chạy `python application-backend-server/app.py` từ thư mục gốc của repo: `app.py` phải đọc `students.json` qua `os.path.join(os.path.dirname(os.path.abspath(__file__)), "students.json")` thay vì đường dẫn tương đối `"students.json"`.
- Gửi `POST /students-db` hoặc `PUT /students-db/<student_id>` với body không phải JSON, thiếu trường bắt buộc (`student_id`, `fullname`, `dob`, `major`) hoặc `dob` sai định dạng ngày `YYYY-MM-DD`: phải trả về HTTP `400 Bad Request` kèm `{"error": "..."}` rõ ràng.
- Gửi `POST /students-db` với `student_id` đã tồn tại trong bảng `students`: phải bắt ngoại lệ `pymysql.err.IntegrityError` và trả về HTTP `409 Conflict` kèm `{"error": "Student ID already exists"}`.
- Gửi `PUT /students-db/<student_id>` hoặc `DELETE /students-db/<student_id>` với `student_id` không tồn tại trong DB: phải trả về HTTP `404 Not Found` kèm `{"error": "Student not found"}`.
- Chạy lặp lại script `relational-database-server/crud_practice.sql` nhiều lần khi tập dượt demo: script phải đảm bảo tính idempotent (xóa bản ghi test `SV005` nếu còn sót lại trước khi `INSERT`) để không bao giờ bị lỗi Duplicate Key.

---

### Task 1: Chuẩn hóa dữ liệu `students.json`, nâng cấp `app.py` (hỗ trợ CRUD `/students-db` & `/health`) và viết Unit Tests

**Files:**
- Modify: `application-backend-server/students.json`
- Modify: `application-backend-server/app.py`
- Modify: `application-backend-server/README.md`
- Create: `application-backend-server/tests/__init__.py`
- Create: `application-backend-server/tests/test_app.py`

**Interfaces:**
- Produces in `application-backend-server/app.py`:
  - `STUDENTS_JSON_PATH: str` (absolute path to `students.json`)
  - `get_db_connection() -> pymysql.connections.Connection`
  - `validate_student_payload(payload: dict, partial: bool = False) -> tuple[bool, str]`
  - `GET /health` -> `200 {"status": "ok", "service": "application-backend-server"}`
  - `GET /hello` -> `200 {"message": "Hello from App Server!"}`
  - `GET /secure` -> `200 {"message": "Secure resource OK", "preferred_username": str, "realm": str, "client_id": str}` | `401 {"error": str}`
  - `GET /student` -> `200 list[dict]`
  - `GET /students-db` -> `200 {"source": "MariaDB (studentdb.students)", "count": int, "students": list[dict]}`
  - `POST /students-db` -> `201 {"message": "Student created successfully", "student": dict}` | `400 {"error": str}` | `409 {"error": str}`
  - `PUT /students-db/<student_id>` -> `200 {"message": "Student updated successfully", "student": dict}` | `400 {"error": str}` | `404 {"error": str}`
  - `DELETE /students-db/<student_id>` -> `200 {"message": "Student deleted successfully", "student_id": str}` | `404 {"error": str}`

- [ ] **Step 1: Tạo bộ Unit Tests kiểm thử toàn diện `application-backend-server/tests/test_app.py`**

Kiểm tra các hành vi sau bằng `unittest` và `unittest.mock`:
- `test_health_and_hello`: `GET /health` trả về `200`, `GET /hello` trả về `200` với `{"message": "Hello from App Server!"}`.
- `test_student_json_from_any_cwd`: Đổi tạm `os.getcwd()` sang thư mục cha và gọi `GET /student`, vẫn trả về `200` với đủ 5 sinh viên có đủ trường `id`, `name`, `major`, `gpa`.
- `test_secure_missing_and_valid_token`: `GET /secure` không có token trả về `401`; có token hợp lệ (mock `extract_realm_from_token`, `get_jwks_for_realm`, `jwt.decode`) trả về `200` với `preferred_username="sv01"`.
- `test_students_db_get`: Mock `get_db_connection`, gọi `GET /students-db` trả về `200` kèm `count` và `students`.
- `test_students_db_post_validation_and_conflict`:
  - `POST /students-db` thiếu trường hoặc `dob="2005-99-99"` trả về `400`.
  - `POST /students-db` bị `pymysql.err.IntegrityError(1062, "Duplicate entry")` trả về `409`.
  - `POST /students-db` hợp lệ trả về `201`.
- `test_students_db_put_and_delete_not_found_and_success`:
  - `PUT /students-db/SV999` khi `cursor.rowcount == 0` (không tồn tại) trả về `404`; khi tồn tại trả về `200`.
  - `DELETE /students-db/SV999` khi `cursor.rowcount == 0` trả về `404`; khi tồn tại trả về `200`.

- [ ] **Step 2: Chạy Unit Tests để xác nhận trạng thái FAIL ban đầu**

Run: `python -m unittest discover -s application-backend-server/tests -p "test_*.py" -v`
Expected: FAIL (do `app.py` chưa có `/health`, `validate_student_payload`, `get_db_connection`, `POST/PUT/DELETE /students-db`).

- [ ] **Step 3: Hoàn thiện `application-backend-server/app.py`, `students.json` và `README.md`**

Triển khai trong `application-backend-server/app.py`:
- Sử dụng `BASE_DIR = os.path.dirname(os.path.abspath(__file__))` và `STUDENTS_JSON_PATH = os.path.join(BASE_DIR, "students.json")`.
- Cài đặt `get_db_connection()` trả về `pymysql.connect(...)`.
- Cài đặt `validate_student_payload(payload: dict, partial: bool = False) -> tuple[bool, str]` kiểm tra kiểu `dict`, các trường `student_id` (tối đa 10 ký tự), `fullname` (tối đa 100 ký tự), `dob` (kiểm tra bằng `datetime.strptime(dob, "%Y-%m-%d")`), `major` (tối đa 50 ký tự).
- Cài đặt `GET /health`, `POST /students-db`, `PUT /students-db/<student_id>`, `DELETE /students-db/<student_id>`.
- Cập nhật `application-backend-server/README.md` bổ sung tài liệu và ví dụ `curl` cho các endpoint mới.

- [ ] **Step 4: Chạy lại Unit Tests xác nhận PASS 100%**

Run: `python -m unittest discover -s application-backend-server/tests -p "test_*.py" -v`
Expected: PASS (tất cả test cases đều `OK`).

- [ ] **Step 5: Commit thay đổi của Task 1 lên nhánh `feat/m2-backend-data-lead`**

```bash
git add application-backend-server/
git commit -m "feat(app): add studentdb CRUD endpoints, path-safe JSON loader, and unit tests"
```

---

### Task 2: Chuẩn hóa Schema MariaDB (`002_studentdb.sql`) và xây dựng kịch bản SQL CRUD tự động (`crud_practice.sql`)

**Files:**
- Modify: `relational-database-server/init/002_studentdb.sql`
- Create: `relational-database-server/crud_practice.sql`
- Modify: `relational-database-server/README.md`

**Interfaces:**
- Consumes: CSDL `studentdb` và bảng `students` (`id`, `student_id`, `fullname`, `dob`, `major`).
- Produces:
  - Ràng buộc `UNIQUE KEY uq_student_id (student_id)` trong `002_studentdb.sql` để đảm bảo tính toàn vẹn dữ liệu và kích hoạt mã lỗi `1062` khi trùng `student_id`.
  - File `relational-database-server/crud_practice.sql` thực hiện idempotent CRUD (`SELECT` -> `INSERT` -> `UPDATE` -> `DELETE`) có nhãn phân tách từng bước rõ ràng khi chạy qua MariaDB CLI.

- [ ] **Step 1: Cập nhật `relational-database-server/init/002_studentdb.sql` bổ sung `UNIQUE` cho `student_id` và đủ 4 bản ghi khởi tạo**

Đảm bảo bảng `students` có định nghĩa:
```sql
CREATE TABLE IF NOT EXISTS students (
  id INT PRIMARY KEY AUTO_INCREMENT,
  student_id VARCHAR(10) NOT NULL UNIQUE,
  fullname VARCHAR(100) NOT NULL,
  dob DATE NOT NULL,
  major VARCHAR(50) NOT NULL
);
```
Và sử dụng `INSERT IGNORE INTO students (student_id, fullname, dob, major) VALUES ...` để script khởi tạo luôn an toàn.

- [ ] **Step 2: Tạo file `relational-database-server/crud_practice.sql` thực hành trọn vẹn chu trình CRUD**

Trong `relational-database-server/crud_practice.sql`:
1. `USE studentdb;`
2. Dọn dẹp trước nếu tồn tại: `DELETE FROM students WHERE student_id = 'SV005';`
3. Bước 1 (READ ban đầu): `SELECT '=== STEP 1: INITIAL SELECT ===' AS info; SELECT * FROM students ORDER BY id;`
4. Bước 2 (CREATE / INSERT): Thêm `('SV005', 'Hoang Minh E', '2005-03-19', 'Information Systems')` và `SELECT * FROM students ORDER BY id;`
5. Bước 3 (UPDATE): Cập nhật `major = 'Cloud Computing & DevOps'` cho `student_id = 'SV005'` và `SELECT * FROM students WHERE student_id = 'SV005';`
6. Bước 4 (DELETE): Xóa `WHERE student_id = 'SV005'` và `SELECT * FROM students ORDER BY id;`

- [ ] **Step 3: Cập nhật `relational-database-server/README.md` hướng dẫn chạy `crud_practice.sql`**

Bổ sung câu lệnh chạy trực tiếp file `crud_practice.sql` vào container `relational-database-server`.

- [ ] **Step 4: Kiểm tra cú pháp và nội dung các file SQL**

Run: `python -c "p='relational-database-server/crud_practice.sql'; s=open(p,encoding='utf-8').read(); assert all(k in s for k in ['INSERT INTO','UPDATE','DELETE FROM','SELECT']); print('SQL CRUD check OK')"`
Expected: `SQL CRUD check OK`

- [ ] **Step 5: Commit thay đổi của Task 2 lên nhánh `feat/m2-backend-data-lead`**

```bash
git add relational-database-server/
git commit -m "feat(db): enforce unique student_id and add idempotent crud_practice.sql script"
```

---

### Task 3: Xây dựng Script Kiểm Thử Tự Động cho Task 2 (`scripts/verify-task2.ps1` & `scripts/verify-task2.sh`)

**Files:**
- Create: `scripts/verify-task2.ps1`
- Create: `scripts/verify-task2.sh`

**Interfaces:**
- Consumes:
  - Unit tests tại `application-backend-server/tests/test_app.py`
  - Endpoints của `application-backend-server` (`:8085` và qua Proxy `:80`)
  - Container `relational-database-server` và file `relational-database-server/crud_practice.sql`
- Produces:
  - Công cụ kiểm tra tự động chạy được trên cả Windows PowerShell (`verify-task2.ps1`) và Linux/Ubuntu EC2 (`verify-task2.sh`).

- [ ] **Step 1: Viết `scripts/verify-task2.ps1` và `scripts/verify-task2.sh`**

Script thực hiện tuần tự:
1. Chạy Unit Tests của `application-backend-server` (`python -m unittest discover -s application-backend-server/tests -p "test_*.py" -v`).
2. Kiểm tra `docker compose config -q`.
3. Nếu container `application-backend-server` và `relational-database-server` đang chạy (`docker ps` có tên container):
   - Test Cơ bản #2: `GET http://localhost:8085/hello` và `GET http://localhost/api/hello`.
   - Test Cơ bản #3: Truy vấn bảng `minicloud.notes` trong `relational-database-server`.
   - Test Mở rộng #2: `GET http://localhost:8085/student`, `GET http://localhost/api/student`, `GET http://localhost/student/`.
   - Test Mở rộng #3 (SQL CRUD): Thực thi `relational-database-server/crud_practice.sql` trong container `relational-database-server`.
   - Test Mở rộng #3 (API CRUD): Gọi `GET /api/students-db`, `POST /api/students-db` (`SV888`), `PUT /api/students-db/SV888`, `DELETE /api/students-db/SV888`.

- [ ] **Step 2: Chạy thử `scripts/verify-task2.ps1` để kiểm chứng**

Run: `powershell -ExecutionPolicy Bypass -File .\scripts\verify-task2.ps1`
Expected: Phần Unit Tests và Docker Compose Config báo `[PASS]` xanh lá (và phần Live Container tests chạy nếu Docker đang bật hoặc báo `[SKIP - Containers not running]` rõ ràng).

- [ ] **Step 3: Commit thay đổi của Task 3 lên nhánh `feat/m2-backend-data-lead`**

```bash
git add scripts/verify-task2.ps1 scripts/verify-task2.sh
git commit -m "test(task2): add automated verification scripts for backend and database tasks"
```

---

### Task 4: Biên soạn Tài liệu Báo cáo Chương 3 & 4 cho Thành viên 2 (`docs/member2-backend-db-report.md`) và Push nhánh lên GitHub

**Files:**
- Create: `docs/member2-backend-db-report.md`
- Create: `docs/superpowers/specs/2026-10-26-task2-backend-database-design.md` *(đã tạo)*
- Create: `docs/superpowers/plans/2026-10-26-task2-backend-database.md` *(file này)*

**Interfaces:**
- Consumes: Cấu trúc đề cương tại `docs/07-REPORT-OUTLINE.md` và toàn bộ code/script từ Task 1–3.
- Produces: Tài liệu báo cáo hoàn chỉnh của Thành viên 2 sẵn sàng ghép vào file Word báo cáo cuối kỳ của nhóm, cùng nhánh `feat/m2-backend-data-lead` được push lên remote `origin`.

- [ ] **Step 1: Viết tài liệu `docs/member2-backend-db-report.md`**

Bao gồm đầy đủ các phần được giao cho Thành viên 2 trong `docs/07-REPORT-OUTLINE.md`:
- **Chương 3 – Mục 3.4:** Cấu hình Application Backend Server (`Dockerfile`, `requirements.txt`, giải thích kiến trúc `app.py`, cơ chế xác thực OIDC JWKS, `students.json`).
- **Chương 3 – Mục 3.5:** Cấu hình Relational Database Server (`001_init.sql`, `002_studentdb.sql`, cơ chế auto-init `/docker-entrypoint-initdb.d/`).
- **Chương 4 – Mục 4.1.3 & 4.1.4:** Kịch bản kiểm thử Cơ bản #2 (`/hello`, `/secure`) và Cơ bản #3 (`minicloud.notes`) kèm chú thích vị trí chèn ảnh chụp màn hình.
- **Chương 4 – Mục 4.2.2 & 4.2.3:** Kịch bản kiểm thử Mở rộng #2 (`/student`) và Mở rộng #3 (`studentdb.students`, `crud_practice.sql`, `/api/students-db` CRUD).
- **Phụ lục Docker Hub của Thành viên 2:** Lệnh chuẩn để build & push `<dockerhub_user>/myminicloud-app:latest`.

- [ ] **Step 2: Kiểm tra trạng thái Git và đảm bảo nhánh `main` không bị thay đổi**

Run: `git branch --show-current`
Expected: `feat/m2-backend-data-lead`

- [ ] **Step 3: Commit tài liệu Thiết kế, Plan và Báo cáo của Thành viên 2, sau đó Push nhánh `feat/m2-backend-data-lead` lên GitHub**

```bash
git add docs/member2-backend-db-report.md docs/superpowers/specs/2026-10-26-task2-backend-database-design.md docs/superpowers/plans/2026-10-26-task2-backend-database.md
git commit -m "docs(task2): add design spec, implementation plan, and chapter 3-4 report for member 2"
git push -u origin feat/m2-backend-data-lead
```
