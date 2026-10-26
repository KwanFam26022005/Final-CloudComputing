# 07. Đề Cương Chi Tiết Báo Cáo Cuối Kỳ (5 Chương + Phụ Lục)

Tài liệu này là khung sườn chuẩn (Template Outline) bám sát 100% yêu cầu trong bảng **"BÁO CÁO CUỐI KỲ PHẢI CÓ"** của đề bài. Các thành viên viết phần nội dung của mình và ghép lại theo đúng bố cục này.

> ⚠️ **Lưu ý quan trọng từ đề bài (Dòng 577):**  
> *"Chú ý, trong báo cáo, SV ghi rõ đã làm được bao nhiêu phần trong mục mở rộng."*  
> 👉 Nhóm cần đặt ngay một **Bảng tổng kết hoàn thành 10/10 yêu cầu mở rộng (5.0/5.0 điểm)** ở đầu Chương 1 và đầu Chương 4.

---

## Trang Bìa & Bảng Phân Công Nhóm
- Tên trường, Khoa Công Nghệ Thông Tin, Môn học: Điện Toán Đám Mây.
- Tên đề tài: **XÂY DỰNG MÔ PHỎNG HỆ THỐNG MINICLOUD CƠ BẢN VÀ MỞ RỘNG (MYMINICLOUD)**.
- Danh sách 4 thành viên (Họ tên, MSSV, Vai trò, Tỷ lệ đóng góp 100%).
- **Bảng xác nhận mức độ hoàn thành:**
  - Phần Cơ bản: **Hoàn thành 10/10 hạng mục (5.0 / 5.0 điểm)**.
  - Phần Mở rộng (Cloud App Integration Practice): **Hoàn thành 10/10 hạng mục (5.0 / 5.0 điểm)**.

---

## CHƯƠNG 1. GIỚI THIỆU & MỤC TIÊU *(Phụ trách: Thành viên 1)*
1.1. **Bối cảnh và lý do chọn đề tài**
   - Xu hướng ảo hóa container (Docker) và kiến trúc Microservices trên nền tảng Cloud (AWS, GCP, Azure).
1.2. **Mục tiêu của hệ thống MyMiniCloud**
   - Mô phỏng đầy đủ 9 thành phần cốt lõi của một Cloud Platform trên mạng nội bộ `cloud-net`.
   - Triển khai thực nghiệm trên môi trường Local và đám mây công cộng AWS EC2 (Ubuntu).
1.3. **Bảng tổng hợp vai trò của 9 loại máy chủ trong hệ thống**
   - Bảng đối chiếu từng container trong MyMiniCloud với dịch vụ tương đương trên AWS (S3, RDS, Cognito/IAM, Route53, CloudWatch, ALB/API Gateway, EC2).
1.4. **Bảng tổng kết mức độ hoàn thành dự án (Cơ bản & 10 mục Mở rộng)**

---

## CHƯƠNG 2. KIẾN TRÚC & SƠ ĐỒ HỆ THỐNG *(Phụ trách: Thành viên 1)*
2.1. **Sơ đồ kiến trúc tổng thể hệ thống MyMiniCloud**
   - Biểu đồ kiến trúc phân tầng: API Gateway/Load Balancer → Web/App/Auth → Database/Object Storage → Monitoring/Logging → Internal DNS.
2.2. **Thiết kế mạng nội bộ Docker (`cloud-net`) & Quy hoạch Port / Network Aliases**
   - Bảng quy hoạch Port (Host Port vs Container Port), Container Name, Network Aliases và DNS Zone `cloud.local`.
2.3. **Luồng xử lý Request (Request Flows)**
   - Luồng truy cập Web tĩnh & Cân bằng tải Round Robin qua Nginx Reverse Proxy.
   - Luồng gọi REST API (`/api/hello`, `/api/student`, `/api/students-db`) và kết nối MariaDB.
   - Luồng xác thực tập trung OIDC/JWT giữa Client – Keycloak – Flask Backend (`/api/secure`).
   - Luồng thu thập Metrics & Trực quan hóa (Node Exporter & Web `/metrics` → Prometheus → Grafana).

---

## CHƯƠNG 3. CẤU HÌNH HẠ TẦNG & DOCKERFILE *(Phụ trách: Cả 4 Thành viên)*
3.1. **Cấu trúc thư mục tổng thể của dự án (`tree`)**
3.2. **File điều phối trung tâm `docker-compose.yml`** *(Thành viên 1)*
3.3. **Cấu hình Web Frontend Server (`Dockerfile`, `conf.default`, cấu trúc Blog)** *(Thành viên 1)*
3.4. **Cấu hình Application Backend Server (`Dockerfile`, `app.py`, `students.json`)** *(Thành viên 2)*
3.5. **Cấu hình Relational Database Server (`001_init.sql`, `002_studentdb.sql`)** *(Thành viên 2)*
3.6. **Cấu hình Authentication Identity Server (Keycloak & Realm `realm_<mssv>`)** *(Thành viên 3)*
3.7. **Cấu hình Object Storage Server (MinIO Buckets & Public Policy)** *(Thành viên 3)*
3.8. **Cấu hình Internal DNS Server (`named.conf.options`, `named.conf.local`, `db.cloud.local`)** *(Thành viên 3)*
3.9. **Cấu hình Monitoring Prometheus & Node Exporter (`prometheus.yml`)** *(Thành viên 4)*
3.10. **Cấu hình Grafana Dashboard & Provisioning** *(Thành viên 4)*
3.11. **Cấu hình API Gateway / Reverse Proxy & Load Balancer (`nginx.conf`)** *(Thành viên 1)*

---

## CHƯƠNG 4. DEMO & KIỂM THỬ HỆ THỐNG *(Phụ trách: Cả 4 Thành viên)*
### 4.1. Kiểm thử Phần Cơ Bản (5.0 Điểm)
- **4.1.1.** Khởi động hệ thống (`docker compose build` & `docker compose up -d` & `docker compose ps`).
- **4.1.2.** Kiểm thử Web Frontend Server (`http://localhost:8080/` & `/blog/`).
- **4.1.3.** Kiểm thử Application Backend Server (`/hello` trực tiếp & `/api/hello` qua Proxy).
- **4.1.4.** Kiểm thử Relational Database Server (Truy vấn bảng `minicloud.notes`).
- **4.1.5.** Kiểm thử Authentication Identity Server (Keycloak Admin Dashboard & user `sv01`).
- **4.1.6.** Kiểm thử Object Storage Server (MinIO bucket `demo` & upload `index.html`).
- **4.1.7.** Kiểm thử Internal DNS Server (`dig` bản ghi `web-frontend-server.cloud.local` → `10.10.10.10`).
- **4.1.8.** Kiểm thử Monitoring Prometheus & Node Exporter (Targets `UP` & Graph `node_cpu_seconds_total`).
- **4.1.9.** Kiểm thử Grafana Dashboard (Datasource Prometheus & Dashboard Node Exporter Full).
- **4.1.10.** Kiểm thử API Gateway Reverse Proxy (`/`, `/api/hello`, `/auth/`) & Kiểm thử `ping` thông mạng toàn bộ container trên `cloud-net`.

### 4.2. Kiểm thử Phần Mở Rộng – Cloud App Integration Practice (5.0 Điểm – Đủ 10/10 Yêu Cầu)
- **4.2.1. [Mở rộng #1 - 0.5đ] Web Frontend:** Demo Blog cá nhân 3 bài viết (`blog1.html`, `blog2.html`, `blog3.html`) kèm ảnh minh họa và liên kết điều hướng.
- **4.2.2. [Mở rộng #2 - 0.5đ] Backend API:** Demo API `/student` và `/api/student` trả về danh sách 5 sinh viên từ `students.json`.
- **4.2.3. [Mở rộng #3 - 0.5đ] Database:** Demo CSDL `studentdb`, bảng `students`, các câu lệnh CRUD (`SELECT`, `UPDATE`, `DELETE`) và API `/api/students-db` đọc trực tiếp từ MariaDB.
- **4.2.4. [Mở rộng #4 - 0.5đ] Keycloak OIDC:** Demo Realm mới `realm_<mssv>`, 2 users (`sv01`, `sv02`), client `flask-app`, lấy JWT Access Token và gọi thành công `/api/secure`.
- **4.2.5. [Mở rộng #5 - 0.5đ] MinIO Storage:** Demo bucket `profile-pics` (truy cập URL public ảnh `avatar.jpg`) và bucket `documents` (chứa file PDF báo cáo).
- **4.2.6. [Mở rộng #6 - 0.5đ] Internal DNS:** Demo kết quả lệnh `dig` phân giải thành công `app-backend.cloud.local`, `minio.cloud.local`, `keycloak.cloud.local`.
- **4.2.7. [Mở rộng #7 - 0.5đ] Prometheus:** Demo trang `/targets` hiển thị target mới `web` (`web-frontend-server:80`) đạt trạng thái `UP`.
- **4.2.8. [Mở rộng #8 - 0.5đ] Grafana:** Demo Dashboard cá nhân `System Health of <MSSV>` gồm 3 biểu đồ CPU Usage, Memory Usage, Network Traffic.
- **4.2.9. [Mở rộng #9 - 0.5đ] API Gateway Route:** Demo truy cập `http://localhost/student/` qua Nginx Reverse Proxy.
- **4.2.10. [Mở rộng #10 - 0.5đ] Load Balancing:** Demo cân bằng tải thuật toán Round Robin luân phiên giữa `web-frontend-server1` và `web-frontend-server2`.

### 4.3. Triển khai và Kiểm thử trên AWS EC2 (Ubuntu) qua Public IP
- Ảnh chụp AWS EC2 Console (Instance Running, Public IPv4, Security Group Inbound Rules).
- Ảnh chụp terminal SSH trên EC2 (`docker compose ps`) và truy cập các dịch vụ qua `http://<EC2_PUBLIC_IP>/...`.

---

## CHƯƠNG 5. ĐÁNH GIÁ, PHÂN TÍCH & HƯỚNG PHÁT TRIỂN *(Phụ trách: Thành viên 4)*
5.1. **Ưu điểm của hệ thống đã xây dựng**
   - Kiến trúc tách biệt theo microservice, dễ mở rộng ngang (scale-out như đã minh chứng với 2 Web Server), tự động hóa khởi tạo cao (DB init SQL, Keycloak realm import, Grafana provisioning).
5.2. **Khó khăn gặp phải & Cách khắc phục**
   - Trình bày cách nhóm phát hiện và xử lý 6 vấn đề kỹ thuật thực tế (Prometheus scrape `/metrics` trên Nginx, OIDC Issuer trong mạng container vs host, cấp phát RAM/Swap trên AWS EC2...).
5.3. **Hướng mở rộng trong tương lai**
   - Nâng cấp lên Docker Swarm / Kubernetes (K8s), bổ sung HTTPS (Let's Encrypt / Certbot), tập trung hóa log với Loki + Promtail, CI/CD GitHub Actions tự động deploy lên EC2.

---

## PHỤ LỤC *(Phụ trách: Thành viên 4 tổng hợp)*
- **Phụ lục A:** Link GitHub Repository (`https://github.com/KwanFam26022005/Final-CloudComputing`) & Ảnh chụp GitHub Insights (Contributors).
- **Phụ lục B:** Link Docker Hub Repository chứa các custom image đã push.
- **Phụ lục C:** Link Video Demo toàn bộ hệ thống (Local + Mở rộng + AWS EC2).
- **Phụ lục D:** Log kết quả chạy script kiểm thử tự động (`verify-base` & `verify-extended`).
