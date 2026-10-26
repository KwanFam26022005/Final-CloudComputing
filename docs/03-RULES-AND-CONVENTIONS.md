# 03. Quy Tắc Làm Việc Nhóm, Quản Lý Git & Quy Chuẩn Kỹ Thuật (Rules & Conventions)

Để nhóm 4 thành viên phối hợp nhịp nhàng, không xảy ra xung đột code (merge conflict), lịch sử đóng góp trên GitHub (`Insights -> Contributors`) minh bạch và đồng đều giữa các thành viên, **tất cả thành viên bắt buộc tuân thủ các quy tắc dưới đây**.

---

## 1. Quy Tắc Phân Định Quyền Sở Hữu Thư Mục (Code Ownership)

Mỗi thành viên chỉ làm việc trực tiếp trong **vùng thư mục được giao**. Không tự ý sửa file trong thư mục của thành viên khác nếu chưa trao đổi trên nhóm:

| Thành viên | Thư mục được quyền chỉnh sửa trực tiếp | File dùng chung (Cần báo nhóm khi sửa) |
| :--- | :--- | :--- |
| **Thành viên 1** | `web-frontend-server/`, `api-gateway-proxy-server/` | `docker-compose.yml`, `README.md` |
| **Thành viên 2** | `application-backend-server/`, `relational-database-server/` | `docker-compose.yml` |
| **Thành viên 3** | `authentication-identity-server/`, `object-storage-server/`, `internal-dns-server/` | `docker-compose.yml` |
| **Thành viên 4** | `monitoring-prometheus-server/`, `monitoring-grafana-dashboard-server/`, `scripts/` | `docker-compose.yml`, `docs/` |

---

## 2. Quy Trình Quản Lý Nhánh Git (Git Branching Strategy)

### 2.1. Cấu trúc nhánh
- **`main`**: Nhánh chính thức, luôn ở trạng thái chạy ổn định (`docker compose up -d` thành công 100%), dùng để deploy lên AWS EC2 và nộp bài. **Cấm push trực tiếp lên `main` khi chưa kiểm thử.**
- **`develop`** *(tùy chọn)* hoặc tách nhánh trực tiếp từ `main` theo quy chuẩn tên nhánh tính năng bên dưới.
- **Nhánh cá nhân theo tính năng (`feat/...`, `fix/...`, `docs/...`):**
  - Định dạng: `<loại>/<mã-thành-viên>-<tên-module-ngắn>`
  - Ví dụ cho **Thành viên 1 (`m1`)**:
    - `feat/m1-web-static-blog`
    - `feat/m1-gateway-load-balancing`
  - Ví dụ cho **Thành viên 2 (`m2`)**:
    - `feat/m2-backend-student-api`
    - `feat/m2-mariadb-studentdb`
  - Ví dụ cho **Thành viên 3 (`m3`)**:
    - `feat/m3-keycloak-realm-oidc`
    - `feat/m3-minio-buckets`
    - `feat/m3-bind9-dns-records`
  - Ví dụ cho **Thành viên 4 (`m4`)**:
    - `feat/m4-prometheus-web-target`
    - `feat/m4-grafana-health-dashboard`
    - `docs/m4-aws-ec2-report`

### 2.2. Quy trình 5 bước khi thực hiện một nhiệm vụ
```bash
# Bước 1: Luôn kéo code mới nhất từ nhánh main về trước khi làm
git checkout main
git pull origin main

# Bước 2: Tạo nhánh riêng cho phần việc của mình
git checkout -b feat/m2-backend-student-api

# Bước 3: Code, cấu hình và chạy thử bằng Docker Compose
docker compose up -d --build
./scripts/verify-base.ps1

# Bước 4: Kiểm tra file thay đổi và Commit với thông điệp rõ ràng
git status
git add application-backend-server/
git commit -m "feat(app): add /student endpoint reading from students.json"

# Bước 5: Push nhánh lên GitHub và tạo Pull Request (PR) vào main
git push -u origin feat/m2-backend-student-api
```

---

## 3. Quy Chuẩn Đặt Tên Commit (Conventional Commits)

Để lịch sử Git chuyên nghiệp và chứng minh rõ đóng góp thực chất của từng thành viên:

### 3.1. Cú pháp chuẩn
```text
<type>(<scope>): <mô tả ngắn gọn, rõ ràng những gì đã làm>
```
Trong đó:
- **`<type>`**:
  - `feat`: Thêm tính năng / cấu hình server mới (cơ bản hoặc mở rộng).
  - `fix`: Sửa lỗi cấu hình, lỗi kết nối mạng, lỗi code.
  - `docs`: Cập nhật tài liệu hướng dẫn, báo cáo, ảnh chụp minh chứng.
  - `test`: Thêm hoặc cập nhật script kiểm thử.
  - `chore`: Cập nhật `.gitignore`, `.env.example`, dọn dẹp dự án.
- **`<scope>`**: Tên module viết ngắn gọn (`web`, `proxy`, `app`, `db`, `auth`, `minio`, `dns`, `prometheus`, `grafana`, `compose`, `docs`).

### 3.2. Ví dụ Commit hợp lệ (Đạt chuẩn) vs Không hợp lệ (Cấm dùng)
- ✅ **Hợp lệ (Nên dùng):**
  - `feat(web): create 3 personal blog posts with images in /blog/`
  - `feat(db): add studentdb schema and seed 3 student records`
  - `feat(app): implement /students-db endpoint connected to MariaDB`
  - `feat(dns): add A records for app-backend, minio, and keycloak in cloud.local`
  - `feat(prometheus): add web-frontend-server scrape job to prometheus.yml`
  - `feat(proxy): configure round-robin load balancing for 2 web servers`
- ❌ **Không hợp lệ (Cấm tuyệt đối):**
  - `update`, `fix`, `abc`, `test 123`, `final`, `upload code`
  - Commit rỗng hoặc chỉ thêm/xóa khoảng trắng vô nghĩa.
  - Dùng tài khoản Git của người khác để commit hộ (mỗi thành viên phải kiểm tra `git config user.name` và `git config user.email` khớp với tài khoản GitHub cá nhân của mình).

---

## 4. Quy Tắc Kỹ Thuật Về Docker, Mạng & Bảo Mật

1. **Không sửa tên mạng `cloud-net`:** Mọi container bắt buộc phải kết nối vào mạng `cloud-net`.
2. **Không xóa `aliases` trong `docker-compose.yml`:** Các alias (`web`, `app-server`, `db`, `keycloak`, `minio`, `dns-server`, `prometheus`, `grafana`) là bắt buộc để các câu lệnh kiểm thử của giảng viên hoạt động.
3. **Không hardcode IP máy cá nhân hoặc `localhost` cho giao tiếp giữa các Container:**
   - Khi Container A gọi Container B (ví dụ: Flask gọi MariaDB, Grafana gọi Prometheus, Nginx gọi Web/App/Auth), **bắt buộc dùng tên service/alias trên mạng `cloud-net`** (ví dụ: `http://prometheus:9090`, `mysql -h db`, `http://application-backend-server:8081`).
   - Chỉ dùng `localhost:<port>` (hoặc `<EC2_PUBLIC_IP>:<port>`) khi gọi từ trình duyệt hoặc terminal của máy Host bên ngoài.
4. **Không đẩy dữ liệu rác dung lượng lớn lên Git:**
   - Không commit thư mục dữ liệu runtime của MinIO (`object-storage-server/data/*` ngoại trừ file mẫu nhỏ nếu cần hoặc dùng script khởi tạo).
   - Không commit thư mục `venv/`, `__pycache__/`, hoặc file `.env` chứa mật khẩu thật trên AWS.
5. **Kiểm tra cú pháp trước khi Push:**
   Luôn chạy lệnh sau và đảm bảo không có lỗi trước khi `git push`:
   ```bash
   docker compose config -q && echo "Config OK!"
   ```
