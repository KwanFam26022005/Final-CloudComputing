# 04. Phân Công Nhiệm Vụ Chi Tiết Cho 4 Thành Viên (Team Work Division)

Tài liệu này chia toàn bộ khối lượng công việc của dự án **MyMiniCloud** (gồm **9 Server Cơ bản + 10 Yêu cầu Mở rộng + Docker Hub + AWS EC2 + Báo Cáo 5 Chương**) thành **4 phần việc cân bằng tuyệt đối** cho 4 thành viên.

---

## 1. Bảng Tổng Quan Phân Công Nhiệm Vụ

| Thành viên | Họ tên & MSSV *(Điền vào)* | Vai trò chính | Server Cơ bản phụ trách | Yêu cầu Mở rộng phụ trách (5.0đ) | Trách nhiệm Hạ tầng & Báo cáo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Thành viên 1** | `[Họ tên - MSSV 1]` | **Gateway & Web Lead** | • `web-frontend-server`<br>• `api-gateway-proxy-server` | • **Mở rộng #1:** Blog cá nhân 3 bài viết HTML (`0.5đ`)<br>• **Mở rộng #9:** Route `/student/` trên Proxy (`0.5đ`)<br>• **Mở rộng #10:** Load Balancing Round Robin 2 Web Servers (`0.5đ`) | • Quản lý `docker-compose.yml` tổng.<br>• Push image `myminicloud-web` lên **Docker Hub**.<br>• **Báo cáo:** Chương 1 & Chương 2. |
| **Thành viên 2** | `[Họ tên - MSSV 2]` | **Backend & Data Lead** | • `application-backend-server`<br>• `relational-database-server` | • **Mở rộng #2:** API `/student` đọc `students.json` (`0.5đ`)<br>• **Mở rộng #3:** Tạo CSDL `studentdb`, bảng `students`, CRUD & API `/students-db` (`0.5đ`) | • Push image `myminicloud-app` lên **Docker Hub**.<br>• **Báo cáo:** Chương 3 & 4 (Phần App Backend & Database). |
| **Thành viên 3** | `[Họ tên - MSSV 3]` | **Security, Storage & DNS Lead** | • `authentication-identity-server`<br>• `object-storage-server`<br>• `internal-dns-server` | • **Mở rộng #4:** Keycloak Realm, Client `flask-app`, 2 Users, test `/secure` (`0.5đ`)<br>• **Mở rộng #5:** MinIO buckets `profile-pics` & `documents` (`0.5đ`)<br>• **Mở rộng #6:** Bind9 thêm DNS records & test `dig` (`0.5đ`) | • Kiểm thử thông mạng nội bộ (`ping`, `dig`).<br>• **Báo cáo:** Chương 3 & 4 (Phần Keycloak, MinIO, DNS). |
| **Thành viên 4** | `[Họ tên - MSSV 4]` | **Observability & Cloud Ops Lead** | • `monitoring-prometheus-server` (+ `node-exporter`)<br>• `monitoring-grafana-dashboard-server` | • **Mở rộng #7:** Prometheus thêm scrape job `web` đạt `UP` (`0.5đ`)<br>• **Mở rộng #8:** Grafana Dashboard `System Health of <MSSV>` gồm 3 biểu đồ (`0.5đ`) | • **Deploy toàn cụm lên AWS EC2 (Ubuntu)**.<br>• **Báo cáo:** Chương 4 (Monitoring & EC2), Chương 5 & Phụ lục. |

---

## 2. Checklist Chi Tiết Từng Thành Viên

### 👤 THÀNH VIÊN 1: Gateway, Web Frontend & Load Balancing
**Thư mục sở hữu:** `web-frontend-server/`, `api-gateway-proxy-server/`

- [ ] **Bước 1 (Cơ bản - Web Server):**
  - Kiểm tra `web-frontend-server/Dockerfile`, `conf.default`, `html/index.html`, và `html/blog/index.html`.
  - Đảm bảo block `location = /metrics` trong `conf.default` hoạt động để hỗ trợ Thành viên 4 scrape Prometheus.
- [ ] **Bước 2 (Mở rộng #1 - Blog cá nhân 3 bài viết - 0.5đ):**
  - Tạo 3 bài viết trong `web-frontend-server/html/blog/`: `blog1.html`, `blog2.html`, `blog3.html`.
  - Mỗi bài có tiêu đề, nội dung, hình ảnh minh họa (SVG/PNG/URL) và nút quay lại trang chính (`/` và `/blog/`).
  - Cập nhật `web-frontend-server/html/index.html` và `html/blog/index.html` có danh sách liên kết (hyperlink) tới 3 bài viết.
- [ ] **Bước 3 (Cơ bản & Mở rộng #9 - API Gateway Routing - 0.5đ):**
  - Kiểm tra `api-gateway-proxy-server/nginx.conf`: đảm bảo định tuyến `/`, `/api/`, `/auth/` hoạt động.
  - Thêm/hoàn thiện route `location /student/` trỏ tới `http://application-backend-server:8081/student`.
- [ ] **Bước 4 (Mở rộng #10 - Load Balancing Round Robin - 0.5đ):**
  - Cấu hình khối `upstream web_backend` trong `api-gateway-proxy-server/nginx.conf` cân bằng tải Round Robin giữa `web-frontend-server:80` và `web-frontend-server2:80`.
  - Chạy lệnh lặp `curl` chứng minh kết quả trả về luân phiên giữa Node 1 và Node 2.
- [ ] **Bước 5 (Docker Hub & Báo cáo):**
  - Build và push image `<dockerhub_user>/myminicloud-web:latest` lên Docker Hub.
  - Viết **Chương 1 (Giới thiệu & Mục tiêu)** và **Chương 2 (Kiến trúc & Sơ đồ)** + mục Web/Proxy trong Chương 3, 4.

---

### 👤 THÀNH VIÊN 2: Application Backend (Flask) & Relational Database (MariaDB)
**Thư mục sở hữu:** `application-backend-server/`, `relational-database-server/`

- [ ] **Bước 1 (Cơ bản - Flask `/hello` & `/secure`):**
  - Kiểm tra `application-backend-server/app.py` và `Dockerfile`.
  - Đảm bảo `GET /hello` trả về `{"message": "Hello from App Server!"}`.
  - Đảm bảo `GET /secure` xác thực được Bearer Token từ Keycloak (phối hợp với Thành viên 3).
- [ ] **Bước 2 (Cơ bản - MariaDB `minicloud`):**
  - Kiểm tra `relational-database-server/init/001_init.sql` tạo DB `minicloud`, bảng `notes` và bản ghi `'Hello from MariaDB!'`.
- [ ] **Bước 3 (Mở rộng #2 - API `/student` từ JSON - 0.5đ):**
  - Hoàn thiện file `application-backend-server/students.json` chứa thông tin **5 sinh viên** (`id`, `name`, `major`, `gpa`).
  - Hoàn thiện route `@app.get("/student")` đọc `students.json` và trả về JSON.
  - Kiểm thử qua cả `http://localhost:8085/student`, `http://localhost/api/student` và `http://localhost/student/`.
- [ ] **Bước 4 (Mở rộng #3 - Database `studentdb` + CRUD + API `/students-db` - 0.5đ):**
  - Trong `relational-database-server/init/002_studentdb.sql`, viết lệnh tạo database `studentdb`, bảng `students` (`id`, `student_id`, `fullname`, `dob`, `major`) và chèn ít nhất **3 sinh viên** (khuyến khích điền tên thật của các thành viên trong nhóm!).
  - Chuẩn bị script/lệnh minh họa truy vấn `SELECT`, `UPDATE`, `DELETE` trên bảng `students`.
  - Trong `application-backend-server/app.py`, hoàn thiện route `@app.get("/students-db")` kết nối trực tiếp tới MariaDB (`studentdb.students`) bằng `pymysql` và trả về JSON qua `http://localhost/api/students-db`.
- [ ] **Bước 5 (Docker Hub & Báo cáo):**
  - Build và push image `<dockerhub_user>/myminicloud-app:latest` lên Docker Hub.
  - Viết phần **Application Server & Database Server** trong Chương 3 và Chương 4 của Báo cáo.

---

### 👤 THÀNH VIÊN 3: Authentication (Keycloak), Object Storage (MinIO) & Internal DNS (Bind9)
**Thư mục sở hữu:** `authentication-identity-server/`, `object-storage-server/`, `internal-dns-server/`

- [ ] **Bước 1 (Cơ bản & Mở rộng #4 - Keycloak OIDC - 0.5đ):**
  - Kiểm tra đăng nhập Keycloak Admin tại `http://localhost:8081` (`admin` / `admin`).
  - Kiểm tra/tùy chỉnh file `authentication-identity-server/import/realm-export.json` (hoặc tạo trên UI rồi export ra file JSON) cho Realm theo mã sinh viên (ví dụ: `realm_sv001`):
    - Gồm 2 users: `sv01` và `sv02` (mật khẩu `123456` hoặc `sv01pass`).
    - Gồm 1 client: `flask-app` (Public client, bật `Direct Access Grants Enabled`).
  - Thực hiện lấy `access_token` qua Token Endpoint và gọi thử `curl -H "Authorization: Bearer <TOKEN>" http://localhost/api/secure` thành công (`200 OK`).
- [ ] **Bước 2 (Cơ bản & Mở rộng #5 - MinIO Object Storage - 0.5đ):**
  - Đăng nhập MinIO Console tại `http://localhost:9001` (`minioadmin` / `minioadmin`).
  - **Cơ bản:** Tạo bucket `demo`, upload file `index.html`.
  - **Mở rộng #5:**
    1. Tạo bucket `profile-pics`, upload file `avatar.jpg`, chỉnh Access Policy của bucket thành **Public**, lấy đường dẫn URL public object mở trên trình duyệt.
    2. Tạo bucket `documents`, upload file PDF báo cáo.
- [ ] **Bước 3 (Cơ bản & Mở rộng #6 - Internal DNS Bind9 - 0.5đ):**
  - Kiểm tra `internal-dns-server/named.conf.options`, `named.conf.local` và `db.cloud.local`.
  - Đảm bảo bản ghi cơ bản `web-frontend-server.cloud.local` trả về `10.10.10.10`.
  - Thêm/kiểm tra các bản ghi mở rộng trong `db.cloud.local`:
    - `app-backend.cloud.local IN A 10.10.10.20`
    - `minio.cloud.local IN A 10.10.10.30`
    - `keycloak.cloud.local IN A 10.10.10.40`
  - Test phân giải tất cả các tên miền trên bằng lệnh `dig @127.0.0.1 -p 1053 <domain> +short`.
- [ ] **Bước 4 (Kiểm thử thông mạng #10 Cơ bản & Báo cáo):**
  - Chạy lệnh `ping -c 3` kiểm tra thông mạng tới toàn bộ 9 servers trong `cloud-net`.
  - Viết phần **Keycloak, MinIO, DNS & Ping Network** trong Chương 3 và Chương 4 của Báo cáo.

---

### 👤 THÀNH VIÊN 4: Monitoring (Prometheus + Grafana) & Triển Khai AWS EC2
**Thư mục sở hữu:** `monitoring-prometheus-server/`, `monitoring-grafana-dashboard-server/`, `scripts/`

- [ ] **Bước 1 (Cơ bản & Mở rộng #7 - Prometheus & Node Exporter - 0.5đ):**
  - Kiểm tra `monitoring-prometheus-server/prometheus.yml`.
  - Đảm bảo job `node` (`monitoring-node-exporter-server:9100`) và job mở rộng `web` (`web-frontend-server:80`) đều hiển thị trạng thái **`UP`** tại `http://localhost:9090/targets`.
  - Thực hiện truy vấn `node_cpu_seconds_total` trên tab Graph của Prometheus.
- [ ] **Bước 2 (Cơ bản & Mở rộng #8 - Grafana Dashboard - 0.5đ):**
  - Kiểm tra cấu hình tự động nạp Datasource Prometheus trong `monitoring-grafana-dashboard-server/provisioning/datasources/prometheus.yml`.
  - **Cơ bản:** Import dashboard **Node Exporter Full** (ID: `1860`) hoặc kiểm tra dashboard có sẵn.
  - **Mở rộng #8:** Kiểm tra/tùy chỉnh dashboard cá nhân **`System Health of <MSSV>`** (đã có file JSON mẫu trong `provisioning/dashboards/`) gồm 3 biểu đồ:
    1. **CPU Usage (%)** (`node_cpu_seconds_total`)
    2. **Memory Usage** (`node_memory_MemAvailable_bytes`)
    3. **Network Traffic** (`node_network_receive_bytes_total`)
- [ ] **Bước 3 (Triển khai thực tế lên AWS EC2 Ubuntu):**
  - Thực hiện theo hướng dẫn tại [`docs/06-AWS-EC2-DEPLOYMENT.md`](./06-AWS-EC2-DEPLOYMENT.md).
  - Khởi tạo EC2 Instance (Ubuntu 22.04/24.04, khuyến nghị `t3.medium` hoặc `t2.medium` có 4GB RAM trở lên vì chạy 10+ containers bao gồm Keycloak & MariaDB).
  - Mở Security Group, clone repo từ GitHub, chạy `docker compose up -d` và chụp ảnh truy cập qua **Public IP của EC2**.
- [ ] **Bước 4 (Báo cáo & Tổng hợp):**
  - Viết phần **Prometheus, Grafana, AWS EC2** trong Chương 3 & 4, viết **Chương 5 (Đánh giá & Phân tích)** và hoàn thiện **Phụ lục**.
