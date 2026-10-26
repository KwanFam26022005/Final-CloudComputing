# 01. Nghiệp Vụ Bài Toán & Yêu Cầu Chấm Điểm (MyMiniCloud)

Tài liệu này tổng hợp đầy đủ yêu cầu nghiệp vụ, yêu cầu kỹ thuật và thang điểm từ đề bài **"Xây dựng mô phỏng hệ thống MiniCloud cơ bản"** (`Báo Cáo Cuối Kỳ.docx`), giúp cả 4 thành viên hiểu thống nhất mục tiêu để đạt **10.0 / 10.0 điểm**.

---

## 1. Bối Cảnh & Mục Tiêu Nghiệp Vụ

Trong thực tế, một nền tảng điện toán đám mây (như **AWS**, **Google Cloud Platform**, **Microsoft Azure**) không phải là một máy chủ đơn lẻ mà là sự kết hợp của nhiều dịch vụ hạ tầng chuyên biệt:
- **Compute & Web Hosting** (tương tự AWS EC2 / S3 Static Hosting / Elastic Beanstalk)
- **Relational Database** (tương tự Amazon RDS)
- **Identity & Access Management - IAM / Cognito** (xác thực người dùng tập trung bằng OIDC/OAuth2)
- **Object Storage** (tương tự Amazon S3 lưu trữ file phi cấu trúc)
- **Private DNS** (tương tự Amazon Route 53 Private Hosted Zone)
- **Monitoring & Observability** (tương tự Amazon CloudWatch)
- **API Gateway & Load Balancer** (tương tự AWS ALB / API Gateway)

**Mục tiêu của dự án MyMiniCloud:**
1. Xây dựng mô hình đám mây thu nhỏ gồm **9 loại máy chủ bắt buộc** chạy trong các container riêng biệt.
2. Tất cả các máy chủ kết nối chung vào một mạng ảo nội bộ **`cloud-net`**.
3. Triển khai và kiểm thử thành công ở cả **máy Local** và **đám mây thực tế AWS EC2 (Ubuntu)** qua địa chỉ Public IP.

---

## 2. Yêu Cầu Kỹ Thuật Chung (Bắt Buộc)

1. **Mạng nội bộ duy nhất:** Tất cả container phải nằm trong Docker network tên `cloud-net`.
2. **Điều phối bằng Docker Compose:** Sử dụng một file `docker-compose.yml` ở thư mục gốc để khởi động toàn bộ cụm.
3. **Tiêu chuẩn cho mỗi Service trong `docker-compose.yml`:**
   - Có `container_name` riêng biệt, rõ ràng.
   - Có cổng (`ports`) ánh xạ hợp lý ra máy host.
   - Có `volumes` để lưu trữ bền vững dữ liệu hoặc gắn file cấu hình.
   - Có chính sách tự khởi động lại: **`restart: unless-stopped`** (áp dụng cho **tất cả** các service).
4. **Docker Hub Registry:** Phải build và push ít nhất **01 image tùy chỉnh** (ví dụ: `<dockerhub_user>/myminicloud-web` và `<dockerhub_user>/myminicloud-app`) lên **Docker Hub**.
5. **Triển khai Cloud thật:** Deploy toàn bộ hệ thống trên **AWS EC2 (Ubuntu)** và truy cập thành công qua **Public IP**.

---

## 3. Phần 1: Yêu Cầu Cơ Bản – Base System (5.0 Điểm)

Để đạt trọn vẹn **5.0 điểm đầu tiên**, hệ thống phải triển khai đủ 9 loại server và vượt qua **10 hạng mục kiểm thử cơ bản** sau:

| Hạng mục | Loại Server | Vai trò chính | Mục tiêu kiểm thử & Cách Demo đạt điểm |
| :-: | :--- | :--- | :--- |
| **1** | **Web Frontend Server**<br>(`web-frontend-server`) | Phục vụ trang web tĩnh `/` và `/blog/` bằng Nginx (`alias`). | • Truy cập `http://localhost:8080/` và `http://localhost:8080/blog/`.<br>• Lệnh `curl -I` trả về `HTTP/1.1 200 OK`.<br>• Hiển thị đúng tiêu đề Home và Blog. |
| **2** | **Application Backend Server**<br>(`application-backend-server`) | Cung cấp REST API (`/hello`, `/secure`) bằng Python Flask. | • Gọi trực tiếp `curl http://localhost:8085/hello` và qua proxy `curl http://localhost/api/hello`.<br>• Cả 2 đều trả về JSON: `{"message":"Hello from App Server!"}`. |
| **3** | **Relational Database Server**<br>(`relational-database-server`) | Quản trị CSDL MariaDB, tự động chạy script khởi tạo lần đầu. | • Tự động tạo DB `minicloud`, bảng `notes` và bản ghi `'Hello from MariaDB!'`.<br>• Truy vấn thành công bảng `notes` bằng client MySQL/MariaDB. |
| **4** | **Authentication Identity Server**<br>(`authentication-identity-server`) | Quản lý định danh, cấp phát JWT token theo chuẩn OIDC (Keycloak). | • Mở `http://localhost:8081`, đăng nhập bằng `admin` / `admin`.<br>• Vào được trang quản trị Dashboard và tạo được user test (`sv01`). |
| **5** | **Object Storage Server**<br>(`object-storage-server`) | Lưu trữ đối tượng tương thích chuẩn S3 bằng MinIO. | • Mở MinIO Console `http://localhost:9001`, đăng nhập `minioadmin` / `minioadmin`.<br>• Tạo bucket `demo` và upload thành công file `index.html`. |
| **6** | **Internal DNS Server**<br>(`internal-dns-server`) | Phân giải tên miền nội bộ cho zone `cloud.local` bằng Bind9. | • Chạy `dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local +short`.<br>• Trả về chính xác địa chỉ IP `10.10.10.10`. |
| **7** | **Monitoring Server**<br>(`monitoring-prometheus-server` + `node-exporter`) | Thu thập metrics tài nguyên hệ thống (CPU, RAM, Network). | • Mở `http://localhost:9090` → `Status` → `Targets`.<br>• Target `monitoring-node-exporter-server:9100` ở trạng thái **`UP`**.<br>• Truy vấn thành công biểu đồ `node_cpu_seconds_total`. |
| **8** | **Visualization Server**<br>(`monitoring-grafana-dashboard-server`) | Trực quan hóa dữ liệu giám sát từ Prometheus bằng Grafana. | • Mở `http://localhost:3000` (`admin` / `admin`).<br>• Kết nối Datasource Prometheus (`http://prometheus:9090`) thành công.<br>• Import dashboard **Node Exporter Full** hiển thị biểu đồ CPU/RAM/Network. |
| **9** | **API Gateway / Reverse Proxy**<br>(`api-gateway-proxy-server`) | Điểm vào duy nhất (Port 80), định tuyến theo đường dẫn (`/`, `/api/`, `/auth/`). | • `curl -I http://localhost/` → `200 OK` (Web).<br>• `curl -s http://localhost/api/hello` → JSON từ Backend.<br>• `curl -I http://localhost/auth/` → Redirect/Response từ Keycloak. |
| **10** | **Kiểm thử thông mạng nội bộ**<br>(`cloud-net` Connectivity) | Xác minh toàn bộ container giao tiếp thông suốt trong mạng `cloud-net`. | • Thực hiện lệnh `ping -c 3` từ một container tới tất cả các server khác (`web`, `app-server`, `db`, `keycloak`, `minio`, `prometheus`, `grafana`, `dns-server`) đều trả về `0% packet loss`. |

---

## 4. Phần 2: Yêu Cầu Mở Rộng – "Cloud App Integration Practice" (5.0 Điểm)

Để đạt **5.0 điểm mở rộng** (tổng cộng 10/10), nhóm phải hoàn thành **10 bài toán tích hợp thực tế** (mỗi mục **0.5 điểm**) dưới đây:

| STT | Server mục tiêu | Yêu cầu nghiệp vụ & Kỹ thuật chi tiết | Cách kiểm chứng (Demo) | Điểm |
| :-: | :--- | :--- | :--- | :-: |
| **1** | **Web Frontend**<br>(`web-frontend-server`) | • Xây dựng blog cá nhân trong `/blog/` gồm ít nhất **3 bài viết HTML** (`blog1.html`, `blog2.html`, `blog3.html`) theo chủ đề tự chọn.<br>• Mỗi bài viết phải có **hình ảnh minh họa** và **liên kết quay lại trang chính**.<br>• Cập nhật `/blog/index.html` và `/index.html` để hiển thị danh sách bài viết kèm hyperlink. | Mở trình duyệt tại `http://localhost:8080/blog/`, click vào từng bài viết `blog1.html`, `blog2.html`, `blog3.html` và nút Back. | **0.5** |
| **2** | **Backend API**<br>(`application-backend-server`) | • Tạo file `students.json` chứa danh sách **5 sinh viên** với đầy đủ trường: `id`, `name`, `major`, `gpa`.<br>• Bổ sung route `GET /student` trong Flask đọc file `students.json` và trả về JSON. | Gọi `curl http://localhost:8085/student` và qua proxy `curl http://localhost/api/student` trả về đúng danh sách 5 sinh viên. | **0.5** |
| **3** | **Database Server**<br>(`relational-database-server` + `app`) | • Tạo CSDL mới tên **`studentdb`**.<br>• Tạo bảng **`students`** gồm: `id INT PRIMARY KEY AUTO_INCREMENT`, `student_id VARCHAR(10)`, `fullname VARCHAR(100)`, `dob DATE`, `major VARCHAR(50)`.<br>• Chèn ít nhất **3 bản ghi**.<br>• Thực hiện các câu lệnh CRUD (`SELECT`, `UPDATE`, `DELETE`).<br>• Kết nối từ Flask App qua API **`GET /students-db`** (qua proxy: `http://localhost/api/students-db`) để trả về dữ liệu trực tiếp từ bảng `studentdb.students`. | 1. Chạy lệnh SQL kiểm tra bảng `studentdb.students` và lịch sử CRUD.<br>2. Gọi `curl http://localhost/api/students-db` trả về JSON dữ liệu từ MariaDB. | **0.5** |
| **4** | **Keycloak Auth**<br>(`authentication-identity-server`) | • Tạo 1 Realm mới theo mã sinh viên/nhóm (ví dụ: `realm_sv001`).<br>• Tạo **2 users**: `sv01` và `sv02` (cài đặt password).<br>• Tạo **1 client**: `flask-app` (Access Type: `public` / bật Direct Access Grants).<br>• Gọi Token Endpoint lấy `access_token` và gọi API bảo mật `/secure` (hoặc `/api/secure`) trên Flask backend. | Dùng `curl` lấy token từ Keycloak Realm mới, sau đó gọi `curl -H "Authorization: Bearer <TOKEN>" http://localhost/api/secure` trả về `200 OK` kèm `"preferred_username": "sv01"`. | **0.5** |
| **5** | **MinIO Storage**<br>(`object-storage-server`) | • Tạo bucket tên **`profile-pics`**, upload ảnh đại diện **`avatar.jpg`**, bật quyền truy cập public (anonymous download policy) và lấy **URL public object** mở trên trình duyệt.<br>• Tạo thêm bucket tên **`documents`** và upload file **PDF báo cáo** của nhóm. | 1. Mở trực tiếp URL public của `avatar.jpg` hiển thị ảnh trên trình duyệt.<br>2. Chụp màn hình bucket `documents` có chứa file `.pdf`. | **0.5** |
| **6** | **Internal DNS**<br>(`internal-dns-server`) | • Mở rộng file `db.cloud.local`, thêm các bản ghi `A`:<br>  - `app-backend.cloud.local IN A 10.10.10.20`<br>  - `minio.cloud.local IN A 10.10.10.30`<br>  - `keycloak.cloud.local IN A 10.10.10.40`<br>• Restart container DNS và kiểm tra phân giải bằng `dig`. | Chạy `dig @127.0.0.1 -p 1053 app-backend.cloud.local +short` (và `minio.cloud.local`, `keycloak.cloud.local`) trả về đúng IP đã cấu hình. | **0.5** |
| **7** | **Prometheus**<br>(`monitoring-prometheus-server`) | • Thêm job mới tên **`web`** trong `prometheus.yml` với `targets: ['web-frontend-server:80']`.<br>• Đảm bảo `web-frontend-server` phản hồi metric hợp lệ tại `/metrics` để target `web` hiển thị trạng thái **`UP`**. | Mở `http://localhost:9090/targets`, cả 2 job `node` và `web` đều hiển thị trạng thái **`UP (1/1)`** màu xanh. | **0.5** |
| **8** | **Grafana Dashboard**<br>(`monitoring-grafana-dashboard-server`) | • Tạo một Dashboard cá nhân mới đặt tên **`System Health of <MSSV>`** gồm ít nhất **3 biểu đồ (Panels)**:<br>  1. **CPU Usage (%)** (`node_cpu_seconds_total`)<br>  2. **Memory Usage** (`node_memory_MemAvailable_bytes`)<br>  3. **Network Traffic** (`node_network_receive_bytes_total`) | Mở Dashboard `System Health of <MSSV>` trên Grafana (`http://localhost:3000`), hiển thị rõ 3 biểu đồ đang chạy dữ liệu thời gian thực. | **0.5** |
| **9** | **API Gateway Route**<br>(`api-gateway-proxy-server`) | • Cấu hình thêm block `location /student/` trong `nginx.conf` trỏ thẳng tới `http://application-backend-server:8081/student`. | Chạy `curl http://localhost/student/` trả về danh sách 5 sinh viên JSON từ backend. | **0.5** |
| **10** | **Load Balancing**<br>(`api-gateway-proxy-server` + 2 Web) | • Khởi chạy 2 instance Web Server: `web-frontend-server1` (hoặc `web-frontend-server`) và `web-frontend-server2`.<br>• Cấu hình `upstream` trong Nginx Reverse Proxy sử dụng thuật toán **Round Robin**.<br>• Kiểm thử truy cập lặp lại vào `http://localhost/` thấy kết quả luân phiên giữa Server 1 và Server 2. | Chạy vòng lặp `curl http://localhost/` (hoặc header/nội dung trang) hiển thị luân phiên `web-frontend-server1` và `web-frontend-server2`. | **0.5** |

---

## 5. Yêu Cầu Đối Với Báo Cáo Cuối Kỳ

Báo cáo nộp cuối kỳ bắt buộc phải có đầy đủ **5 Chương + Phụ lục** và **ghi rõ số lượng phần mở rộng nhóm đã hoàn thành (10/10 phần)**:
- **Chương 1. Giới thiệu & mục tiêu:** Giải thích hệ thống 9 server, mô hình cloud mô phỏng.
- **Chương 2. Kiến trúc & sơ đồ:** Sơ đồ network, flow request giữa các server.
- **Chương 3. Cấu hình & Dockerfile:** Trình bày các Dockerfile, `docker-compose.yml`, file config của từng dịch vụ.
- **Chương 4. Demo & kiểm thử:** Ảnh chụp màn hình minh họa kết quả chạy thực tế của từng server (Cơ bản + Mở rộng + AWS EC2).
- **Chương 5. Đánh giá & phân tích:** Nêu ưu điểm – khó khăn – hướng mở rộng.
- **Phụ lục:** Link GitHub, Link Docker Hub, Link Video Demo, Log kết quả kiểm thử, Bảng xác nhận hoàn thành 10/10 mục mở rộng.
