# Kết quả nghiệm thu — Local và EC2, release v1.0-final

> **Local**: Windows 11 + Docker Desktop, Docker 28.4, Compose v2.39.4, image `dev`, commit kiểm thử f0acb68. Hai image `v1.0` đã push Docker Hub lúc ~16:13 ngày 10/11/2026. **EC2**: Ubuntu 24.04, c7i-flex.large, 11 container Up, source tag `v1.0-final` (4737c47), Web/App pull từ Docker Hub. Thời gian nghiệm thu Local: ~15:20–15:56; EC2: ~16:23–16:26 ngày 10/11/2026 (GMT+7).
> Commit `9981b30` (T0.1) và `f0acb68` (T0.2) đã có trên `origin/main` khi kiểm tra lại lúc ~16:13.

## Bảng kết quả (Local)

| ID | Hạng mục | Môi trường | Thời điểm | Lệnh/Thao tác | Kết quả quan sát | Trạng thái | Ảnh |
|----|----------|-----------|-----------|---------------|------------------|-----------|-----|
| B1 | Web | Local | 15:42 | `curl.exe -I http://localhost:8080/` và `/blog/` + trình duyệt | HTTP/1.1 200 OK; title "MyMiniCloud – Home" / "– Blog" | PASS | co-ban-web.png |
| B2 | App | Local | 15:42 | `curl.exe -s :8085/hello`; `curl.exe -s http://localhost/api/hello` | Cả hai `{"message":"Hello from App Server!"}` | PASS | co-ban-app.png |
| B3 | DB | Local | 15:42 | `docker exec relational-database-server mariadb -uroot -p*** -e "SELECT * FROM minicloud.notes;"` | 1 dòng `Hello from MariaDB!` | PASS | co-ban-database.png |
| B4 | Keycloak | Local | 15:52 | Admin Console `localhost:8081` (admin lab) → realm_52300107 → Users | Thấy `sv01`, `sv02`; client `flask-app` | PASS | co-ban-keycloak.png |
| B5 | MinIO | Local | 15:34 | Bucket `demo` + `index.html` (upload/tải về bằng SDK minio, xem bằng Console) | SHA256 gốc = SHA256 tải về (`825887ee…a6a3`) | PASS (upload qua SDK, xem Console) | co-ban-minio.png |
| B6 | DNS | Local | 15:42 | `nslookup -port=1053 ...`; `dig @127.0.0.1 ... +short` trong container; UDP raw từ host | dig = `10.10.10.10`; UDP raw từ host = `10.10.10.10`; **`nslookup.exe` Windows báo "No response"** (Sự cố #3) | PASS (có lưu ý) | co-ban-dns.png |
| B7 | Prometheus | Local | 15:50 | `/targets`, query `node_cpu_seconds_total` | job node 1/1 UP; `count(node_cpu_seconds_total)`=64 | PASS | co-ban-prometheus.png |
| B8 | Grafana | Local | 15:51 | Dashboard Node Exporter Full; datasource health API | Datasource `status OK`; biểu đồ CPU/RAM/Network có dữ liệu. Nút "Save & test" trên UI không chụp được kết quả (Sự cố #6) | PASS (có lưu ý) | co-ban-grafana.png |
| B9 | Gateway | Local | 15:42 | `curl.exe -I http://localhost/`; `/api/hello`; `-I /auth/` | 200; JSON; `/auth/` → 302 `Location: http://localhost/admin/` (gateway không route `/admin` → 404, xem Hạn chế) | PASS | co-ban-gateway-network.png |
| B10 | Mạng cloud-net | Local | 15:42 | ping 8 alias từ `object-storage-server` | 8/8 `0% packet loss` | PASS | co-ban-gateway-network.png |
| E1 | Blog | Local | 15:50 | Trình duyệt `/blog/`, `blog1..3.html` | 3 bài hiển thị, link quay lại có | PASS | mo-rong-blog.png |
| E2 | /student | Local | 15:42 | `curl.exe -s :8085/student`; `/api/student` | 5 SV, đủ `id,name,major,gpa` | PASS | mo-rong-student.png |
| E3 | studentdb | Local | 15:43 | DESCRIBE/SELECT, `crud_practice.sql`, `/api/students-db`, `verify-task2.ps1` | Schema `id,student_id,fullname,dob,major`; 4 dòng (≥3); CRUD chạy không lỗi; API `count=4`; unit test 6/6 OK; task2 không có FAIL | PASS | mo-rong-studentdb.png |
| E4 | Keycloak OIDC | Local | 15:43 | `.\scripts\verify-task4.ps1` | `SUMMARY TASK4: FAIL=0`; sv01/sv02 200 trực tiếp và qua Gateway; thiếu/sai token → 401; chữ ký sửa → 401. flask-app public + Direct Access Grants | PASS | mo-rong-oidc.png |
| E5 | MinIO | Local | 15:44 | Bucket `profile-pics` + policy Custom GetObject `avatar.jpg`; `documents` + PDF; `verify-task5.ps1` | Avatar ẩn danh HTTP 200 `image/jpeg`; PDF ẩn danh 403; `SUMMARY TASK5: FAIL=0`. **Avatar và PDF là PLACEHOLDER** | PASS (placeholder) | mo-rong-storage.png |
| E6 | DNS mở rộng | Local | 15:43 | restart DNS; dig ×3; `verify-task6.ps1` | `.20`, `.30`, `.40`; `SUMMARY TASK6: FAIL=0` (nslookup.exe lỗi như B6) | PASS (có lưu ý) | mo-rong-dns.png |
| E7 | Prometheus job web | Local | 15:44 | `/metrics`, `/targets`; stop/start web2 | web 2/2 UP; stop web2 → `up=0` sau 35s; start → `up=1` | PASS | mo-rong-web-metrics.png |
| E8 | Dashboard | Local | 15:51 | Grafana `System Health of 52300140`, 15 phút | 3 panel CPU Usage (%), Memory Usage (%), Network Traffic có dữ liệu | PASS | mo-rong-dashboard.png |
| E9 | /student/ | Local | 15:43 | `curl.exe -s http://localhost/student/` | 5 SV giống E2 | PASS | mo-rong-route.png |
| E10 | Round Robin | Local | 15:44 | 6 lần `curl.exe -sI http://localhost/` | server1, server2 luân phiên (6/6) | PASS | mo-rong-round-robin.png |

EC2: đã chạy bộ kiểm thử cơ bản/mở rộng và Task4/5/6. Xem bảng kết quả EC2 bên dưới; việc xác nhận UI bằng tài khoản quản trị và dữ liệu cá nhân cuối cùng vẫn cần hoàn thiện.

## Tổng hợp
Local: cơ bản 10/10, mở rộng 10/10 (B6, B8, E5, E6 có lưu ý/placeholder, xem dưới). EC2: bộ cơ bản PASS=26 FAIL=0, mở rộng PASS=17 FAIL=0; không quy đổi các con số kiểm tra nhỏ này thành số ảnh/ca UI đã nghiệm thu.

### Nghiệm thu EC2 ngày 10/11/2026

| Kiểm tra | Kết quả | Log/ảnh |
|---|---|---|
| Khởi động hệ thống | 11/11 container Up; MinIO healthy | logs/ec2-compose-ps.txt |
| Cơ bản | SUMMARY: PASS=26 FAIL=0, exit 0 | logs/ec2-verify-base.txt |
| Mở rộng | SUMMARY: PASS=17 FAIL=0, exit 0 | logs/ec2-verify-extended.txt |
| Task4 OIDC | FAIL=0, exit 0 | logs/ec2-task4.txt |
| Task5 Storage | FAIL=0, exit 0; chưa chạy quyền readonly | logs/ec2-task5.txt |
| Task6 DNS/mạng | FAIL=0, exit 0 | logs/ec2-task6.txt |
| OIDC qua Public IP từ Windows | OIDC, App trực tiếp và Gateway exit 0; mỗi API secure 5/5 PASS | logs/ec2-public-oidc.txt, ec2-public-app-secure.txt, ec2-public-gateway-secure.txt |
| HTTP từ Windows | Web, hello, student, student route, students-db, avatar, Prometheus health đều HTTP 200 | logs/ec2-public-http.txt |
| Round Robin qua Public IP | 6 request luân phiên Primary/Replica | logs/ec2-public-http.txt |
| Trình duyệt Chrome | Home, Prometheus Targets và student route truy cập được | evidence/ec2-dich-vu.png, ec2-prometheus.png, ec2-student.png |

Máy: i-09b1a1559442a57b3, Public IP 13.229.212.14, c7i-flex.large, 30 GB gp3 encrypted.
Chi tiết truy cập và vị trí file mật khẩu (không chứa mật khẩu): EC2-ACCESS.md.
Máy đang Running. Ba máy Lab 6/7/8 khác không thay đổi.

MinIO EC2 có demo/index.html đúng source, avatar tạm public và PDF báo cáo nghiệm thu Local thực tế
4.7 MB (bao-cao-nghiem-thu-local.pdf), không phải PDF placeholder 610 byte của Local.
Chưa thay avatar cá nhân và chưa có PDF nộp cuối; chưa chụp AWS Console/SG và UI quản trị EC2.
Chưa thực hiện recreate/reboot toàn cụm EC2 hoặc thử issuer/audience/expiry, readonly/expiry thực tế.

Trình duyệt Edge tự động chặn HTTP với ERR_BLOCKED_BY_CLIENT; Chrome truy cập thành công.
evidence/ec2-browser-error.png chỉ ghi nhận lỗi Edge, không dùng làm minh chứng PASS.

### Log script tổng (Local)
| Log | Kết quả |
|---|---|
| logs/local-verify-base.txt | `SUMMARY: PASS=26 FAIL=0` (exit 0) |
| logs/local-verify-extended.txt | `SUMMARY: PASS=17 FAIL=0` (exit 0) |
| logs/local-verify-extended-after-restart.txt | `SUMMARY: PASS=17 FAIL=0` (sau `compose down` + `up -d`) |
| logs/local-verify-base-after-restart.txt | `SUMMARY: PASS=26 FAIL=0` (bổ sung) |

Sau restart: `studentdb.students` còn 4 dòng, bucket MinIO + avatar public còn, realm `realm_52300107` còn (token sv01 OK, `verify-extended` pass).

### Kiểm tra T0.1/T0.2
- T0.1: `docker compose config` hợp lệ; ghi thêm dòng `T01TEST`, `down` → `up -d` → `COUNT(*)` giữ nguyên (5), sau đó đã xóa dòng thử (còn 4).
- T0.2: cụm khỏe → `FAIL=0` exit 0 (ps1 và sh). `docker stop web-frontend-server2` → `verify-extended` báo 2 FAIL (target web2 DOWN, Round Robin chỉ thấy server1), exit 1 (ps1 và sh); đã `docker start` lại. `verify-base` không kiểm web2 nên vẫn `FAIL=0`.

## Dữ liệu placeholder (cần thay)
- `profile-pics/avatar.jpg`: ảnh JPEG **tạm** do executor sinh bằng Pillow (400×400). **Người dùng thay bằng ảnh thật**, giữ nguyên tên và policy.
- `documents/bao-cao-nhap.pdf`: PDF 1 trang **nháp** (610 B, chữ ASCII "PDF nhap bao cao - se thay ban cuoi"). **Thay bằng PDF báo cáo cuối ở T5.1** (cả Local và EC2) và chụp lại `mo-rong-storage.png`.

## Sự cố
| # | Hiện tượng | Output | Nguyên nhân | Xử lý | Kiểm tra lại |
|---|---|---|---|---|---|
| 1 | `docker compose config` lỗi trên `main` | `yaml: unmarshal errors: line 261: mapping key "volumes" already defined at line 12` | `docker-compose.yml` có **hai** khối `volumes:` cấp cao nhất (grafana-data ở đầu, keycloak_data ở cuối) | Gộp thành một khối cùng thêm `mariadb_data` (commit `9981b30`, T0.1) | `docker compose config -q` rc=0 |
| 2 | `docker compose` không chạy trong môi trường executor | `docker: unknown command: docker compose` | Docker CLI không tìm thấy thư mục plugin `D:\Docker\resources\cli-plugins` (lỗi cấu hình máy, không phải repo) | Dùng `docker-compose.exe` và, cho các script gọi `docker compose` (verify-task2/6), đặt tạm `DOCKER_CONFIG` trỏ tới config riêng có `cliPluginsExtraDirs` (chỉ trong tiến trình, không sửa config người dùng/repo) | `docker compose config -q` rc=0, task2/6 chạy |
| 3 | `nslookup.exe -port=1053 <name> 127.0.0.1` trên Windows báo `No response from server` | `*** UnKnown can't find web-frontend-server.cloud.local: No response from server` | Chưa xác định chắc chắn; máy chủ Bind9 trả lời đúng (dig trong container và truy vấn UDP/TCP raw từ host tới 127.0.0.1:1053 đều `10.10.10.10`) → nhiều khả năng do nslookup.exe Windows + cổng tùy chỉnh/Docker Desktop UDP proxy | Không sửa; dùng `dig` trong container + UDP raw làm bằng chứng. **Nên thử lại nslookup trên máy người dùng/EC2 (bash)** | logs/dns-host-udp1053.txt |
| 4 | `docker compose build` lỗi | `failed to solve: image "docker.io/kwanfam/myminicloud-web:dev": already exists` | `web-frontend-server` và `web-frontend-server2` build song song cùng một tag image (containerd image store của Docker Desktop) | Không sửa code; `docker compose up -d` tự build và thành công (11 container Up). Lưu ý cho T0.3/EC2: build/push riêng từng service `web-frontend-server`, `application-backend-server` | 11 container Up |
| 5 | Không chạy được `docker compose down -v` của T1.0 | (chặn bởi cơ chế phân quyền của executor) | Xóa volume bị từ chối | Bỏ `-v`; các volume (`cloud_mariadb_data`, `grafana-data`, `n07-keycloak-data`) đều mới tạo trong phiên này (trước đó không tồn tại) nên tương đương khởi động sạch | `docker volume ls`; DB khởi tạo mới 4 dòng |
| 6 | Nút "Save & test" của Grafana trên UI không hiện kết quả trong ảnh chụp | (không thấy thông báo) | Cửa sổ trình duyệt tự động rất thấp (529 px), thông báo nằm ngoài vùng chụp | Dùng API `/api/datasources/uid/prometheus/health` → `status OK`; **chụp lại thủ công nếu cần ảnh Save & test** | logs/b8.txt |
| 7 | `verify-extended` FAIL ở mục #5 (avatar) khi mới `up` | `[FAIL] Avatar chua doc public duoc.` | Dữ liệu MinIO không theo Git — chưa tạo bucket/policy | Đúng thiết kế sau T0.2; đã tạo dữ liệu (E5) rồi chạy lại → `FAIL=0` | local-verify-extended.txt |
| 8 | `/auth/` qua Gateway trả 302 → `http://localhost/admin/` (404 khi theo redirect) | `Location: http://localhost/admin/` | Gateway chỉ route `/auth/`; Keycloak chuyển hướng sang `/admin/` không có route | Không sửa code. `verify-base` (T0.2) kiểm 3xx không theo redirect | logs/b9.txt |

## Hạn chế (cho Chương 5)
- Backend tắt `verify_iss`/`verify_aud` của JWT (`application-backend-server/app.py:145`) — chỉ xác minh chữ ký RS256 bằng JWKS; không sửa để tránh làm hỏng demo OIDC.
- Keycloak chạy `start-dev` (H2, HTTP, `KC_HOSTNAME_STRICT=false`), mật khẩu admin/mặc định lab (`admin/admin`, `minioadmin`, `root`, `sv01pass`…) — không dùng cho production; trên EC2 bắt buộc đổi.
- Dữ liệu MinIO (bucket `demo`, `profile-pics/avatar.jpg` + policy, `documents` + PDF) không theo Git → phải tạo tay mỗi lần deploy mới; `verify-extended` sẽ FAIL ở mục #5 cho tới khi tạo xong.
- Gateway `/auth/` chuyển hướng sang `/admin/` không được route (Sự cố #8); Keycloak và App còn truy cập trực tiếp qua cổng host 8081/8085.
- Avatar Local/EC2 còn tạm; PDF Local còn placeholder, PDF EC2 là báo cáo nghiệm thu Local nháp. Docker Hub đã public; tag `v1.0-final` đã có trên remote và EC2 đã qua kiểm thử tự động, còn hoàn thiện ảnh/UI và dữ liệu cuối cùng.
- `docker compose build` song song hai service cùng image có thể lỗi "already exists" (Sự cố #4).

## Bằng chứng
Ảnh trong `docs/acceptance/evidence/` (20 ảnh Local + 2 sơ đồ). Ảnh dạng **render văn bản từ output lệnh** (không phải chụp terminal thật): `co-ban-khoi-dong`, `co-ban-app`, `co-ban-database`, `co-ban-dns` (phần text), `co-ban-gateway-network` (phần text), `mo-rong-student`, `mo-rong-studentdb`, `mo-rong-route`, `mo-rong-round-robin`, `mo-rong-dns`. Ảnh ghép trình duyệt + text: `co-ban-web`, `co-ban-keycloak`, `co-ban-minio`, `co-ban-prometheus`, `co-ban-grafana`, `mo-rong-blog`, `mo-rong-oidc`, `mo-rong-storage`, `mo-rong-web-metrics`, `mo-rong-dashboard`. Hai sơ đồ (`kien-truc-tong-the.png`, `luong-request.png`) vẽ bằng Pillow theo nguồn `.mmd` kèm theo (không chạy được `npx mermaid-cli`).
