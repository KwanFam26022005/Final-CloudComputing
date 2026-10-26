# Thiết Kế Kiến Trúc & Foundation: MyMiniCloud (`Final-CloudComputing`)

**Ngày:** 2026-10-26  
**Dự án:** Xây dựng mô phỏng hệ thống MiniCloud cơ bản & mở rộng (MyMiniCloud)  
**Repository:** `https://github.com/KwanFam26022005/Final-CloudComputing`  
**Phương án chọn:** Phương án A – Modular Boilerplate + Docs chuẩn cho nhóm 4 thành viên

---

## 1. Mục tiêu hệ thống (System Goals)

1. Xây dựng nền tảng (Foundation) cho hệ thống **MyMiniCloud** gồm **9 loại máy chủ bắt buộc** (+ `monitoring-node-exporter-server`) chạy trên mạng Docker nội bộ `cloud-net`.
2. Đảm bảo nhóm 4 thành viên có thể phát triển song song, độc lập theo từng module mà không xung đột code, đạt tối đa **10.0 / 10.0 điểm** (5.0 điểm Cơ bản + 5.0 điểm Mở rộng).
3. Khắc phục triệt để **6 bẫy kỹ thuật** trong tài liệu đề bài mẫu:
   - **Trap 1:** `web-frontend-server` cung cấp endpoint `/metrics` chuẩn Prometheus exposition format để job `web` trong Prometheus luôn đạt trạng thái `UP`.
   - **Trap 2:** Khai báo đầy đủ `networks.cloud-net.aliases` (`web`, `app-server`, `db`, `keycloak`, `minio`, `dns-server`, `prometheus`, `grafana`, `node-exporter`, `proxy`) để tương thích 100% với mọi lệnh kiểm thử dùng tên ngắn hoặc tên dài.
   - **Trap 3:** `application-backend-server` tách biệt URL lấy JWKS nội bộ (`OIDC_INTERNAL_ISSUER` / `JWKS_URL`) và xác thực linh hoạt `issuer`/`audience` cho cả Realm `master` và Realm mở rộng (`realm_minicloud` / `realm_<mssv>`).
   - **Trap 4:** Hỗ trợ tự động nạp cấu hình qua **Keycloak Realm Import** (`--import-realm`) và **Grafana Provisioning** (`datasources` + `dashboards`) để không mất dữ liệu khi redeploy hoặc chuyển lên AWS EC2.
   - **Trap 5:** Toàn bộ 100% services trong `docker-compose.yml` đều có `restart: unless-stopped`.
   - **Trap 6:** Hỗ trợ sẵn cấu trúc để mở rộng từ 1 Web Server sang 2 Web Servers (`web-frontend-server1`, `web-frontend-server2`) phục vụ Load Balancing Round Robin ở Yêu cầu Mở rộng 10.

---

## 2. Quy hoạch Kiến trúc, Cổng (Ports) & Định danh Mạng (`cloud-net`)

| STT | Thư mục / Service | Container Name | Network Aliases (`cloud-net`) | Port (Host:Container) | Thành viên phụ trách |
| :-: | :--- | :--- | :--- | :---: | :---: |
| 1 | `web-frontend-server` | `web-frontend-server` | `web`, `web-frontend-server1` | `8080:80` | Thành viên 1 |
| 1b | *(Mở rộng LB)* `web-frontend-server2` | `web-frontend-server2` | `web2` | `8082:80` | Thành viên 1 |
| 2 | `application-backend-server` | `application-backend-server` | `app`, `app-server`, `app-backend` | `8085:8081` | Thành viên 2 |
| 3 | `relational-database-server` | `relational-database-server` | `db`, `mysql`, `mariadb` | `3306:3306` | Thành viên 2 |
| 4 | `authentication-identity-server` | `authentication-identity-server` | `keycloak`, `auth` | `8081:8080` | Thành viên 3 |
| 5 | `object-storage-server` | `object-storage-server` | `minio`, `storage` | `9000:9000`, `9001:9001` | Thành viên 3 |
| 6 | `internal-dns-server` | `internal-dns-server` | `dns`, `dns-server` | `1053:53/udp`, `1053:53/tcp` | Thành viên 3 |
| 7a | *(Image)* `monitoring-node-exporter-server` | `monitoring-node-exporter-server` | `node-exporter` | `9100:9100` | Thành viên 4 |
| 7b | `monitoring-prometheus-server` | `monitoring-prometheus-server` | `prometheus`, `monitor` | `9090:9090` | Thành viên 4 |
| 8 | `monitoring-grafana-dashboard-server` | `monitoring-grafana-dashboard-server` | `grafana` | `3000:3000` | Thành viên 4 |
| 9 | `api-gateway-proxy-server` | `api-gateway-proxy-server` | `proxy`, `gateway` | `80:80` | Thành viên 1 |

---

## 3. Cấu trúc Bộ Tài Liệu (`docs/`) & Quy Tắc Quản Lý

1. `docs/01-BUSINESS-AND-REQUIREMENTS.md`: Phân tích nghiệp vụ bài toán MyMiniCloud, chi tiết 9 server cơ bản (5đ) và 10 yêu cầu mở rộng (5đ), tiêu chí chấm điểm tối đa.
2. `docs/02-ARCHITECTURE-AND-NETWORK.md`: Sơ đồ kiến trúc tổng thể, luồng request qua API Gateway, sơ đồ xác thực OIDC, bảng quy hoạch Port/Alias/DNS zone `cloud.local`, giải thích 6 bẫy kỹ thuật.
3. `docs/03-RULES-AND-CONVENTIONS.md`: Quy tắc làm việc nhóm bắt buộc (Branching strategy, Commit message theo Conventional Commits, quy tắc Pull Request, quy tắc cô lập thư mục, quy tắc Docker & bảo mật).
4. `docs/04-TEAM-WORK-DIVISION.md`: Bảng phân công chi tiết cho 4 thành viên, danh sách file sở hữu, checklist công việc từng tuần và hướng dẫn phối hợp tích hợp.
5. `docs/05-TESTING-AND-DEMO-GUIDE.md`: Toàn bộ lệnh kiểm thử 10 mục Cơ bản + 10 mục Mở rộng (kèm kết quả kỳ vọng và hướng dẫn chụp ảnh minh chứng báo cáo).
6. `docs/06-AWS-EC2-DEPLOYMENT.md`: Hướng dẫn chuẩn bị Docker Hub, khởi tạo máy chủ AWS EC2 (Ubuntu), cấu hình Security Group, deploy và kiểm thử qua Public IP.
7. `docs/07-REPORT-OUTLINE.md`: Đề cương chi tiết Báo Cáo Cuối Kỳ (5 Chương + Phụ lục) phân bổ rõ phần viết cho từng thành viên.

---

## 4. Cấu trúc Boilerplate cho 9 Server & Scripts Tự Động

- Mỗi thư mục trong 9 server có:
  - Các file cấu hình / mã nguồn khung chuẩn (chạy lên được ngay ở mức cơ bản và có sẵn vị trí đánh dấu `TODO [Mở rộng #...]` rõ ràng cho thành viên phụ trách hoàn thiện).
  - File `README.md` riêng trong từng thư mục hướng dẫn thành viên phụ trách cách code, cách build và lệnh test module đó.
- Thư mục `scripts/`:
  - `verify-base.ps1` và `verify-base.sh`: Kiểm thử tự động toàn bộ yêu cầu cơ bản (5 điểm).
  - `verify-extended.ps1` và `verify-extended.sh`: Kiểm thử tự động các yêu cầu mở rộng (5 điểm).
