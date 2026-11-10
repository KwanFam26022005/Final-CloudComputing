# 05. Cẩm Nang Kiểm Thử & Kịch Bản Demo Đạt 10/10 Điểm

Tài liệu này cung cấp danh sách đầy đủ các câu lệnh kiểm thử cho **10 bài kiểm thử Cơ bản (5.0 điểm)** và **10 bài kiểm thử Mở rộng (5.0 điểm)** để các thành viên tự kiểm tra code và chụp ảnh minh chứng đưa vào Báo cáo Chương 4.

---

## Phần A: Khởi Động Sạch Cụm Container Trước Khi Test

```bash
# 1. Di chuyển vào thư mục gốc của dự án
cd Final-CloudComputing

# 2. Dừng và xóa container cũ (nếu muốn làm mới hoàn toàn)
docker compose down

# 3. Build mới các image (Web & App) và khởi chạy ngầm
docker compose build --no-cache
docker compose up -d

# 4. Kiểm tra toàn bộ container đã ở trạng thái Up/Running
docker compose ps
```

---

## Phần B: 10 Bài Kiểm Thử Cơ Bản (5.0 Điểm)

### 1️⃣ Web Frontend Server (`web-frontend-server`)
```bash
curl -I http://localhost:8080/
curl -I http://localhost:8080/blog/
curl -s http://localhost:8080/
```
- **Kỳ vọng:** Trả về `HTTP/1.1 200 OK`, nội dung hiển thị `MyMiniCloud – Home` và `MyMiniCloud Blog`.

### 2️⃣ Application Backend Server (`application-backend-server`)
```bash
# Gọi trực tiếp tới cổng Backend (8085)
curl http://localhost:8085/hello

# Gọi thông qua API Gateway Proxy (cổng 80)
curl http://localhost/api/hello
```
- **Kỳ vọng:** Cả 2 câu lệnh đều trả về `{"message":"Hello from App Server!"}`.

### 3️⃣ Relational Database Server (`relational-database-server`)
```bash
# Cách 1: Dùng docker exec trực tiếp vào container DB
docker exec -it relational-database-server mariadb -uroot -proot -e "SHOW DATABASES; USE minicloud; SHOW TABLES; SELECT * FROM notes;"

# Cách 2: Chạy đúng câu lệnh trong đề bài (nhờ network alias 'db')
docker run --rm --network cloud-net mariadb:11 sh -lc 'mariadb -h db -uroot -proot -e "USE minicloud; SHOW TABLES; SELECT * FROM notes;"'
```
- **Kỳ vọng:** Hiển thị bảng `notes` và bản ghi `Hello from MariaDB!`.

### 4️⃣ Authentication Identity Server (`authentication-identity-server`)
- Mở trình duyệt truy cập: `http://localhost:8081`
- Đăng nhập tài khoản quản trị: **`admin` / `admin`**
- **Kỳ vọng:** Vào được trang Admin Console của Keycloak, kiểm tra danh sách Users có user `sv01`.

Kiểm thử task4: `bash scripts/verify-task4.sh` hoặc `./scripts/verify-task4.ps1`.
Script kiểm token hai user, App/Gateway và volume. Python 3 chạy các verify Auth trong `scripts/`.
Thao tác đăng nhập/tạo user trên UI vẫn cần minh chứng như đề.

### 5️⃣ Object Storage Server (`object-storage-server`)
- Mở trình duyệt truy cập MinIO Console: `http://localhost:9001`
- Đăng nhập: **`minioadmin` / `minioadmin`**
- Tạo bucket tên **`demo`** và upload file `web-frontend-server/html/index.html`.
- **Kỳ vọng:** File `index.html` xuất hiện trong bucket `demo`.

Kiểm thử task5: `bash scripts/verify-task5.sh` hoặc `./scripts/verify-task5.ps1`.
Script dùng venv/SDK đã hướng dẫn trong README Storage để kiểm bytes HTML, JPEG, PDF và link ký.
Upload/download qua Console và nội dung PDF báo cáo cần kiểm thực tế.

### 6️⃣ Internal DNS Server (`internal-dns-server`)
```bash
# Nếu máy có cài dig:
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local +short

# Hoặc chạy dig ngay từ bên trong container mạng cloud-net (không cần cài dig trên Windows):
docker exec internal-dns-server dig "@127.0.0.1" web-frontend-server.cloud.local +short
```
- **Kỳ vọng:** Trả về `10.10.10.10`.

Kiểm thử task6: `bash scripts/verify-task6.sh` hoặc `./scripts/verify-task6.ps1`.
Script kiểm cú pháp, bốn record qua UDP/TCP và ping tám alias. Chuẩn bị đủ container trước khi ping.

### 7️⃣ Monitoring Node Exporter + Prometheus (`monitoring-prometheus-server`)
- Mở trình duyệt: `http://localhost:9090/targets`
- **Kỳ vọng:** Target `monitoring-node-exporter-server:9100` có trạng thái **`UP`** màu xanh lá.
- Chuyển sang tab **Graph** (`http://localhost:9090/graph`), nhập `node_cpu_seconds_total` và nhấn **Execute**.

### 8️⃣ Monitoring Grafana Dashboard (`monitoring-grafana-dashboard-server`)
- Mở trình duyệt: `http://localhost:3000`
- Đăng nhập: **`admin` / `admin`**
- Kiểm tra **Connections → Data sources**: Datasource `Prometheus` (`http://prometheus:9090`) đã được kết nối sẵn (hoặc nhấn *Save & test* báo xanh).
- Vào **Dashboards → New → Import**, nhập ID **`1860`** (Node Exporter Full) → Load → Chọn datasource Prometheus → Import.

### 9️⃣ API Gateway Proxy Server (`api-gateway-proxy-server`)
```bash
curl -I http://localhost/
curl -s http://localhost/api/hello
curl -I http://localhost/auth/
```
- **Kỳ vọng:**
  - `/`: `HTTP/1.1 200 OK`
  - `/api/hello`: `{"message":"Hello from App Server!"}`
  - `/auth/`: `HTTP/1.1 200 OK` hoặc `302 Found` chuyển hướng tới trang Keycloak.

### 🔟 Kiểm thử thông mạng nội bộ (`ping` giữa các server trên `cloud-net`)
```bash
docker exec api-gateway-proxy-server sh -c '
  for host in web app-server db keycloak minio prometheus grafana dns-server; do
    echo "=== PING $host ==="
    ping -c 3 $host
  done
'
```
- **Kỳ vọng:** Tất cả 8 lệnh `ping` đều trả về `3 packets transmitted, 3 packets received, 0% packet loss`.

---

## Phần C: 10 Bài Kiểm Thử Mở Rộng – Cloud App Integration (5.0 Điểm)

### 🌟 Mở rộng 1: Blog cá nhân 3 bài viết HTML (`0.5đ`)
```bash
curl -I http://localhost:8080/blog/blog1.html
curl -I http://localhost:8080/blog/blog2.html
curl -I http://localhost:8080/blog/blog3.html
```
- Mở trình duyệt tại `http://localhost:8080/` và `http://localhost:8080/blog/`, chụp ảnh danh sách bài viết và giao diện từng bài viết (`blog1.html`, `blog2.html`, `blog3.html`) có hình ảnh minh họa.

### 🌟 Mở rộng 2: Backend API `/student` đọc từ file `students.json` (`0.5đ`)
```bash
curl -s http://localhost:8085/student
curl -s http://localhost/api/student
```
- **Kỳ vọng:** Trả về mảng JSON gồm 5 sinh viên (`id`, `name`, `major`, `gpa`).

### 🌟 Mở rộng 3: Database `studentdb` + Bảng `students` + CRUD + API `/students-db` (`0.5đ`)
```bash
# 1. Kiểm tra bảng students trong CSDL studentdb
docker exec -it relational-database-server mariadb -uroot -proot -e "USE studentdb; DESCRIBE students; SELECT * FROM students;"

# 2. Thực hiện thử CRUD (INSERT, UPDATE, DELETE)
docker exec -it relational-database-server mariadb -uroot -proot -e "
  USE studentdb;
  INSERT INTO students(student_id, fullname, dob, major) VALUES ('SV999', 'Nguyen Van Test', '2005-01-15', 'Cloud Computing');
  SELECT * FROM students;
  UPDATE students SET major='Data Science & Cloud' WHERE student_id='SV999';
  SELECT * FROM students WHERE student_id='SV999';
  DELETE FROM students WHERE student_id='SV999';
  SELECT * FROM students;
"

# 3. Kiểm tra API Flask đọc trực tiếp từ MariaDB qua Proxy
curl -s http://localhost/api/students-db
```

### 🌟 Mở rộng 4: Keycloak Realm mới + Client `flask-app` + 2 Users (`sv01`, `sv02`) + Test `/secure` (`0.5đ`)
```bash
# 1. Lấy Access Token cho user sv01 từ Realm realm_52300107
TOKEN=$(curl -s -X POST "http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=flask-app" \
  -d "username=sv01" \
  -d "password=sv01pass" \
  -d "grant_type=password" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

test -n "$TOKEN" || { echo "FAIL: khong lay duoc token"; exit 1; }

# 2. Gọi API /secure qua Proxy kèm Bearer Token
curl -s -H "Authorization: Bearer $TOKEN" http://localhost/api/secure
unset TOKEN
```
- **Kỳ vọng:** Trả về `{"message":"Secure resource OK","preferred_username":"sv01","realm":"realm_52300107"}` với mã `200 OK`.

Chạy `verify-task4.sh`/`.ps1` để kiểm cả `sv01`, `sv02`: Token/UserInfo 200; API trực tiếp và
qua Gateway đúng identity; thiếu/sai token và sửa chữ ký bị 401. Sai issuer/audience/hết hạn và
browser `/auth/` cần kiểm riêng. Không in/chụp token thật.

Cải tiến task4:

```bash
# Recreate Auth, giu volume; co gian doan ngan.
bash scripts/verify-task4.sh --recreate-auth
```

PowerShell: `./scripts/verify-task4.ps1 -RecreateAuth`.
Mặc định script kiểm mount; thêm tham số recreate để kiểm tra giữ dữ liệu sau khi tạo lại container.

### 🌟 Mở rộng 5: MinIO Buckets `profile-pics` (Public Avatar) & `documents` (PDF) (`0.5đ`)
1. Vào `http://localhost:9001`, mở bucket **`profile-pics`**, upload `avatar.jpg`, cấp quyền GET public cho object theo README Storage.
2. Truy cập trực tiếp URL public: `http://localhost:9000/profile-pics/avatar.jpg` trên trình duyệt.
3. Tạo bucket **`documents`**, upload file PDF báo cáo và chụp màn hình minh chứng.

Task5 kiểm `demo/index.html` khớp source, JPEG public, các PDF hiện có, PDF unsigned403,
link ký200 đúng bytes và link sửa chữ ký403. PDF demo chưa thay PDF báo cáo cuối kỳ thật.
Nếu source vừa cập nhật, đối chiếu/upload lại đúng index.html; script không tự ghi đè dữ liệu.

Cải tiến tài khoản đọc: `bash scripts/verify-task5.sh --readonly` hoặc
`./scripts/verify-task5.ps1 -ReadOnly`. Cần tài khoản `n07-storage-verifier` đã có và hai biến
`N07_MINIO_ACCESS_KEY`, `N07_MINIO_SECRET_KEY`; nhập secret theo README Storage, không ghi vào lịch sử lệnh.
Phép thử tạo/dọn object UUID, kiểm đọc được và PUT/DELETE/admin bị403; bucket policy/PDF cũ giữ nguyên.
Thời điểm hết hạn link thực tế vẫn cần kiểm riêng theo README.

Chuẩn bị venv SDK cho task5 (chạy một lần nếu chưa có):

```bash
python3 -m venv object-storage-server/.venv
object-storage-server/.venv/bin/python -m pip install -r object-storage-server/requirements-client.txt
```

PowerShell: `py -3 -m venv object-storage-server/.venv`, rồi
`./object-storage-server/.venv/Scripts/python.exe -m pip install -r object-storage-server/requirements-client.txt`.

#### Chạy kiểm thử tài khoản MinIO đọc

Cần tài khoản `n07-storage-verifier` và SDK theo [README Storage](../object-storage-server/README.md). Chạy từ gốc dự án; nhập mật khẩu tài khoản này khi được hỏi.

Tài khoản demo local: **`n07-storage-verifier`** — mật khẩu **`123456789abcdef@`**. Mật khẩu đã cập nhật trên máy Hùng; máy khác cần tạo/cập nhật tài khoản theo README Storage với cùng mật khẩu.

**Mac (zsh):**

```zsh
export N07_MINIO_ACCESS_KEY=n07-storage-verifier
read -rs 'N07_MINIO_SECRET_KEY?Nhập mật khẩu tài khoản kiểm thử: '
echo
export N07_MINIO_SECRET_KEY
PYTHONDONTWRITEBYTECODE=1 bash scripts/verify-task5.sh --readonly
echo "Exit code: $?"
unset N07_MINIO_ACCESS_KEY N07_MINIO_SECRET_KEY
```

**Windows (PowerShell):**

```powershell
$env:N07_MINIO_ACCESS_KEY = "n07-storage-verifier"
$secret = Read-Host "Nhập mật khẩu tài khoản kiểm thử" -AsSecureString
$env:N07_MINIO_SECRET_KEY = [System.Net.NetworkCredential]::new("", $secret).Password
.\scripts\verify-task5.ps1 -ReadOnly
Write-Host "Exit code: $LASTEXITCODE"
Remove-Item Env:N07_MINIO_ACCESS_KEY, Env:N07_MINIO_SECRET_KEY
Remove-Variable secret
```

**Kỳ vọng:** đọc thành công; ghi/xóa/admin bị `403`; file tạm được dọn; `SUMMARY TASK5: FAIL=0`, exit code `0`.

### 🌟 Mở rộng 6: Internal DNS thêm bản ghi `app-backend`, `minio`, `keycloak` (`0.5đ`)
```bash
docker exec internal-dns-server sh -c '
  dig @127.0.0.1 web-frontend-server.cloud.local +short
  dig @127.0.0.1 app-backend.cloud.local +short
  dig @127.0.0.1 minio.cloud.local +short
  dig @127.0.0.1 keycloak.cloud.local +short
'
```
- **Kỳ vọng:** Lần lượt trả về `10.10.10.10`, `10.10.10.20`, `10.10.10.30`, `10.10.10.40`.

Task6 báo từng record/protocol PASS khi `NOERROR`, có `aa` và đúng IP; đủ tám query.
Ping báo từng đích riêng. Nếu `bad address`, dùng `docker compose ps --all` kiểm container tương ứng
đang chạy và cùng `cloud-net`; Docker alias khác bản ghi `*.cloud.local` của Bind9.
Task6 không tự đổi zone/restart dịch vụ.

Các script riêng in `SUMMARY TASK4/5/6: FAIL=...`; exit0 khi ca đã chạy đạt, exit1 khi lỗi,
exit2 khi thiếu điều kiện. `[NOT RUN]` là phần tùy chọn chưa được chọn, không tính PASS.
`base`/`extended` vẫn là bộ chung; task2 của TV2 giữ nguyên. Chạy script không thay minh chứng UI/EC2.

### 🌟 Mở rộng 7: Prometheus Scrape Target `web-frontend-server:80` đạt `UP` (`0.5đ`)
- Mở `http://localhost:9090/targets`.
- **Kỳ vọng:** Cả 2 target `node` (`monitoring-node-exporter-server:9100`) và `web` (`web-frontend-server:80`) đều hiển thị trạng thái **`UP`** màu xanh.

### 🌟 Mở rộng 8: Grafana Dashboard cá nhân `System Health of <MSSV>` (`0.5đ`)
- Mở `http://localhost:3000` → **Dashboards**.
- Mở dashboard **`System Health of SV001`** (hoặc đổi tên theo MSSV của nhóm), chụp ảnh màn hình hiển thị rõ 3 biểu đồ: **CPU Usage (%)**, **Memory Usage**, **Network Traffic**.

### 🌟 Mở rộng 9: API Gateway Route `/student/` (`0.5đ`)
```bash
curl -s http://localhost/student/
```
- **Kỳ vọng:** Trả về danh sách 5 sinh viên JSON từ `application-backend-server`.

### 🌟 Mở rộng 10: Load Balancing Round Robin giữa 2 Web Server (`0.5đ`)
```bash
# Gọi 6 lần liên tiếp vào cổng 80 của Proxy để kiểm tra luân phiên Round Robin
for i in 1 2 3 4 5 6; do
  echo "Request #$i:"
  curl -s -I http://localhost/ | grep -i "X-Served-By"
done
```
- **Kỳ vọng:** Kết quả in ra luân phiên đều đặn giữa `X-Served-By: web-frontend-server1 (Primary)` và `X-Served-By: web-frontend-server2 (Replica)`.
