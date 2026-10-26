# MyMiniCloud Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng trọn bộ Foundation (Tài liệu nghiệp vụ, Kiến trúc, Rules, Phân công 4 thành viên, Boilerplate 9 servers, Docker Compose và Scripts kiểm thử) cho dự án cuối kỳ `Final-CloudComputing`.

**Architecture:** Kiến trúc Multi-Container Micro-Cloud gồm 9 dịch vụ cốt lõi (+ Node Exporter) giao tiếp qua mạng nội bộ `cloud-net` với đầy đủ DNS nội bộ, Reverse Proxy/Load Balancer, OIDC Identity, RDBMS, S3 Object Storage và Prometheus/Grafana Observability.

**Tech Stack:** Docker, Docker Compose, Nginx, Python 3.11 (Flask, PyMySQL, python-jose), MariaDB 11, Keycloak, MinIO, Bind9, Prometheus, Node Exporter, Grafana, PowerShell & Bash scripts.

**Spec:** `docs/superpowers/specs/2026-10-26-myminicloud-foundation-design.md`

## Global Constraints

- Mạng Docker bắt buộc tên `cloud-net`.
- Mọi service trong `docker-compose.yml` bắt buộc có `container_name`, `restart: unless-stopped`, và `networks.cloud-net.aliases` khớp với cả tên dài lẫn tên ngắn trong đề bài.
- Các cổng (ports) tuân thủ đúng quy hoạch: Web (`8080:80`), App (`8085:8081`), DB (`3306:3306`), Auth (`8081:8080`), MinIO (`9000:9000`, `9001:9001`), DNS (`1053:53/udp`), Prometheus (`9090:9090`), NodeExporter (`9100:9100`), Grafana (`3000:3000`), Proxy (`80:80`).

## Review Focus

- Prometheus scrape `web-frontend-server:80/metrics` phải trả về HTTP 200 với định dạng text metric hợp lệ để target `web` luôn `UP`.
- Các lệnh `ping` và `mysql -h db` trong đề bài sử dụng hostname ngắn (`db`, `web`, `app-server`, `keycloak`, `minio`, `prometheus`, `grafana`, `dns-server`) phải phân giải được qua Docker network aliases.
- Cấu hình Nginx Proxy `/api/` phải strip prefix `/api/` chính xác khi chuyển tiếp sang `application-backend-server:8081/`.
- File `.gitignore` phải chặn thư mục dữ liệu runtime (`object-storage-server/data/*`) nhưng giữ lại `.gitkeep` để cấu trúc thư mục luôn tồn tại khi clone.
- Toàn bộ tài liệu hướng dẫn trong `docs/` phải rõ ràng, chi tiết và thống nhất với cấu trúc code boilerplate.

---

### Task 1: Khởi tạo Root Configs (`.gitignore`, `.env.example`, `docker-compose.yml`, `README.md`)

**Files:**
- Create: `.gitignore`
- Create: `.env.example`
- Create: `docker-compose.yml`
- Create: `README.md`

- [ ] **Step 1: Tạo `.gitignore`, `.env.example`, `docker-compose.yml`, `README.md` chuẩn hóa**
- [ ] **Step 2: Kiểm tra cú pháp `docker compose config`**

### Task 2: Xây dựng Bộ Tài Liệu Quản Lý & Nghiệp Vụ (`docs/01` -> `docs/07`)

**Files:**
- Create: `docs/01-BUSINESS-AND-REQUIREMENTS.md`
- Create: `docs/02-ARCHITECTURE-AND-NETWORK.md`
- Create: `docs/03-RULES-AND-CONVENTIONS.md`
- Create: `docs/04-TEAM-WORK-DIVISION.md`
- Create: `docs/05-TESTING-AND-DEMO-GUIDE.md`
- Create: `docs/06-AWS-EC2-DEPLOYMENT.md`
- Create: `docs/07-REPORT-OUTLINE.md`
- Create: `.github/pull_request_template.md`

- [ ] **Step 1: Viết đầy đủ 7 tài liệu chuyên sâu trong `docs/` và PR template**

### Task 3: Xây dựng Boilerplate cho 9 Thư Mục Server (Domains của 4 Thành Viên)

**Files:**
- Create: `web-frontend-server/` (`Dockerfile`, `conf.default`, `html/index.html`, `html/blog/index.html`, `README.md`)
- Create: `api-gateway-proxy-server/` (`nginx.conf`, `README.md`)
- Create: `application-backend-server/` (`Dockerfile`, `requirements.txt`, `app.py`, `students.json`, `README.md`)
- Create: `relational-database-server/` (`init/001_init.sql`, `init/002_studentdb_template.sql`, `README.md`)
- Create: `authentication-identity-server/` (`import/realm-export.json`, `README.md`)
- Create: `object-storage-server/` (`data/.gitkeep`, `README.md`)
- Create: `internal-dns-server/` (`named.conf.options`, `named.conf.local`, `db.cloud.local`, `README.md`)
- Create: `monitoring-prometheus-server/` (`prometheus.yml`, `README.md`)
- Create: `monitoring-grafana-dashboard-server/` (`provisioning/datasources/prometheus.yml`, `provisioning/dashboards/dashboard.yml`, `README.md`)

- [ ] **Step 1: Khởi tạo toàn bộ boilerplate và README hướng dẫn riêng cho từng server**

### Task 4: Xây dựng Scripts Kiểm Thử Tự Động (`scripts/`) & Kiểm chứng

**Files:**
- Create: `scripts/verify-base.ps1`
- Create: `scripts/verify-base.sh`
- Create: `scripts/verify-extended.ps1`
- Create: `scripts/verify-extended.sh`

- [ ] **Step 1: Tạo các script kiểm thử tự động PowerShell và Bash**
- [ ] **Step 2: Chạy `docker compose config` kiểm tra tính hợp lệ của toàn bộ hệ thống và commit**
