# ☁️ MyMiniCloud – Hệ Thống Mô Phỏng Nền Tảng Đám Mây (Final Project)

> **Môn học:** Điện Toán Đám Mây (Cloud Computing)  
> **Repository:** [KwanFam26022005/Final-CloudComputing](https://github.com/KwanFam26022005/Final-CloudComputing)  
> **Mục tiêu:** Xây dựng hệ thống Cloud thu nhỏ (**MyMiniCloud**) gồm **9 loại máy chủ cốt lõi** chạy trên các Docker Container độc lập, giao tiếp qua mạng nội bộ `cloud-net`, tích hợp đầy đủ **10 yêu cầu mở rộng (Cloud App Integration Practice)** và triển khai thực tế trên **AWS EC2 (Ubuntu)**.

---

## 📚 Mục Lục Tài Liệu Nền Tảng (`docs/`)

Toàn bộ thành viên trong nhóm **BẮT BUỘC** đọc kỹ bộ tài liệu trong thư mục [`docs/`](./docs/) trước khi bắt đầu code:

| Tài liệu | Nội dung chính | Đối tượng đọc |
| :--- | :--- | :--- |
| [**`01-BUSINESS-AND-REQUIREMENTS.md`**](./docs/01-BUSINESS-AND-REQUIREMENTS.md) | Phân tích nghiệp vụ bài toán, 9 loại server bắt buộc (5.0đ), 10 yêu cầu mở rộng (5.0đ) và tiêu chí chấm điểm tối đa (10/10). | Cả nhóm (4 thành viên) |
| [**`02-ARCHITECTURE-AND-NETWORK.md`**](./docs/02-ARCHITECTURE-AND-NETWORK.md) | Sơ đồ kiến trúc tổng thể, luồng đi của Request, bảng quy hoạch Port/Container/Aliases, DNS Zone và cách xử lý **6 bẫy kỹ thuật** của đề bài. | Cả nhóm (4 thành viên) |
| [**`03-RULES-AND-CONVENTIONS.md`**](./docs/03-RULES-AND-CONVENTIONS.md) | **QUY TẮC BẮT BUỘC:** Quy trình Git (Branch, Commit, PR), quy tắc cô lập thư mục, quy chuẩn Docker & bảo mật. | Cả nhóm (4 thành viên) |
| [**`04-TEAM-WORK-DIVISION.md`**](./docs/04-TEAM-WORK-DIVISION.md) | Bảng phân công nhiệm vụ chi tiết cho **4 thành viên** (Code cơ bản + Mở rộng + Hạ tầng + Chương báo cáo) kèm Checklist cá nhân. | Cả nhóm (4 thành viên) |
| [**`05-TESTING-AND-DEMO-GUIDE.md`**](./docs/05-TESTING-AND-DEMO-GUIDE.md) | Cẩm nang lệnh kiểm thử từng bước cho 10 bài test Cơ bản + 10 bài test Mở rộng + Hướng dẫn chụp ảnh minh chứng. | Cả nhóm (4 thành viên) |
| [**`06-AWS-EC2-DEPLOYMENT.md`**](./docs/06-AWS-EC2-DEPLOYMENT.md) | Hướng dẫn push Docker Hub, khởi tạo máy chủ AWS EC2 (Ubuntu), mở cổng Security Group và chạy qua Public IP. | Thành viên 1, 2, 4 |
| [**`07-REPORT-OUTLINE.md`**](./docs/07-REPORT-OUTLINE.md) | Khung sườn Báo Cáo Cuối Kỳ (5 Chương + Phụ lục) chuẩn theo yêu cầu giảng viên. | Cả nhóm (4 thành viên) |

---

## 🏗️ Kiến Trúc 9 Loại Máy Chủ Trong Hệ Thống

| STT | Thư mục / Module | Loại Máy Chủ | Công nghệ / Image | Port (Host:Container) | Network Aliases (`cloud-net`) | Phụ trách |
| :-: | :--- | :--- | :--- | :---: | :--- | :---: |
| **1** | [`web-frontend-server/`](./web-frontend-server/) | **Web Server** *(+ Replica LB)* | Nginx Stable (Custom Build) | `8080:80` *(Replica: `8082:80`)* | `web`, `web-frontend-server1` | **Thành viên 1** |
| **2** | [`application-backend-server/`](./application-backend-server/) | **Application Server** | Python 3.11 + Flask + OIDC + PyMySQL | `8085:8081` | `app`, `app-server`, `app-backend` | **Thành viên 2** |
| **3** | [`relational-database-server/`](./relational-database-server/) | **Database Server** | MariaDB 11 | `3306:3306` | `db`, `mysql`, `mariadb` | **Thành viên 2** |
| **4** | [`authentication-identity-server/`](./authentication-identity-server/) | **Authentication Server** | Keycloak (OIDC / SSO) | `8081:8080` | `keycloak`, `auth` | **Thành viên 3** |
| **5** | [`object-storage-server/`](./object-storage-server/) | **Object Storage Server** | MinIO (S3 Compatible) | `9000:9000`, `9001:9001` | `minio`, `storage` | **Thành viên 3** |
| **6** | [`internal-dns-server/`](./internal-dns-server/) | **Internal DNS Server** | ISC Bind9 (`cloud.local`) | `1053:53/udp` | `dns`, `dns-server` | **Thành viên 3** |
| **7** | [`monitoring-prometheus-server/`](./monitoring-prometheus-server/) | **Monitoring Server** *(+ Node Exporter)* | Prometheus + Node Exporter | `9090:9090` *(Exporter: `9100:9100`)* | `prometheus`, `node-exporter` | **Thành viên 4** |
| **8** | [`monitoring-grafana-dashboard-server/`](./monitoring-grafana-dashboard-server/) | **Visualization Server** | Grafana | `3000:3000` | `grafana` | **Thành viên 4** |
| **9** | [`api-gateway-proxy-server/`](./api-gateway-proxy-server/) | **API Gateway / Reverse Proxy** | Nginx Reverse Proxy & Load Balancer | `80:80` | `proxy`, `gateway` | **Thành viên 1** |

---

## 👥 Phân Công Nhóm (4 Thành Viên)

| Thành viên | Vai trò (Role) | Phạm vi thư mục sở hữu (Code Ownership) | Nhiệm vụ Mở rộng (5.0đ) | Phần Báo Cáo |
| :--- | :--- | :--- | :--- | :--- |
| **Thành viên 1** | **Gateway & Web Lead** | `web-frontend-server/`, `api-gateway-proxy-server/`, `docker-compose.yml` | **#1** (Blog 3 bài viết), **#9** (Route `/student/`), **#10** (Load Balancing Round Robin 2 Web) | Chương 1 & Chương 2 |
| **Thành viên 2** | **Backend & Data Lead** | `application-backend-server/`, `relational-database-server/` | **#2** (API `/student` JSON), **#3** (CSDL `studentdb` + bảng `students` + CRUD + `/students-db`) | Chương 3 (App & DB) |
| **Thành viên 3** | **Security, Storage & DNS Lead** | `authentication-identity-server/`, `object-storage-server/`, `internal-dns-server/` | **#4** (Keycloak Realm, Client, User, `/secure`), **#5** (MinIO `profile-pics` & `documents`), **#6** (DNS records) | Chương 3 & 4 (Auth, S3, DNS) |
| **Thành viên 4** | **Observability & Cloud Ops Lead** | `monitoring-prometheus-server/`, `monitoring-grafana-dashboard-server/`, `scripts/` | **#7** (Prometheus scrape `web` UP), **#8** (Grafana Dashboard 3 biểu đồ CPU/RAM/Net) + **Deploy AWS EC2** | Chương 4, Chương 5 & Phụ lục |

> Chi tiết checklist từng bước cho mỗi thành viên xem tại: [**`docs/04-TEAM-WORK-DIVISION.md`**](./docs/04-TEAM-WORK-DIVISION.md).

---

## 🚀 Hướng Dẫn Khởi Động Nhanh (Quick Start)

### 1. Yêu cầu môi trường
- **Docker Desktop** (Windows/macOS) hoặc **Docker Engine + Docker Compose v2** (Ubuntu/Linux).
- **Git**, **curl**, và công cụ kiểm thử DNS (`nslookup` hoặc `dig`).

### 2. Khởi tạo và chạy toàn bộ cụm MiniCloud
```bash
# 1. Clone dự án về máy
git clone https://github.com/KwanFam26022005/Final-CloudComputing.git
cd Final-CloudComputing

# 2. Tạo file .env từ mẫu (tùy chọn)
cp .env.example .env

# 3. Build các custom image (Web & App) và khởi chạy toàn bộ container
docker compose build --no-cache
docker compose up -d

# 4. Kiểm tra trạng thái các container
docker compose ps
```

### 3. Chạy Script Kiểm Thử Tự Động
- **Trên Windows (PowerShell):**
  ```powershell
  # Kiểm thử 10 yêu cầu Cơ bản (5.0 điểm)
  .\scripts\verify-base.ps1

  # Kiểm thử 10 yêu cầu Mở rộng (5.0 điểm)
  .\scripts\verify-extended.ps1
  ```
- **Trên Linux / macOS / AWS EC2 (Bash):**
  ```bash
  chmod +x scripts/*.sh
  ./scripts/verify-base.sh
  ./scripts/verify-extended.sh
  ```

---

## 🔗 Danh Sách Điểm Truy Cập Nhanh (Endpoints)

- **API Gateway (Điểm vào hợp nhất):** `http://localhost/`
  - Trang Web qua Proxy: `http://localhost/` và `http://localhost/blog/`
  - Backend API qua Proxy: `http://localhost/api/hello`, `http://localhost/api/student`, `http://localhost/student/`
  - Keycloak qua Proxy: `http://localhost/auth/`
- **Web Frontend trực tiếp (Node 1 / Node 2):** `http://localhost:8080/` | `http://localhost:8082/`
- **Application Backend trực tiếp:** `http://localhost:8085/hello`
- **Keycloak Admin Console:** `http://localhost:8081` *(Tài khoản: `admin` / `admin`)*
- **MinIO Console (Object Storage):** `http://localhost:9001` *(Tài khoản: `minioadmin` / `minioadmin`)*
- **Prometheus UI:** `http://localhost:9090/targets`
- **Grafana Dashboard:** `http://localhost:3000` *(Tài khoản: `admin` / `admin`)*
