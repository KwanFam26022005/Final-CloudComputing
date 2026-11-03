# 05. Cẩm Nang Kiểm Thử & Kịch Bản Demo Theo Đề Cuối Kỳ

Tài liệu này cung cấp danh sách đầy đủ các câu lệnh kiểm thử cho **10 bài kiểm thử Cơ bản (5.0 điểm)** và **10 bài kiểm thử Mở rộng (5.0 điểm)** để các thành viên tự kiểm tra code và chụp ảnh minh chứng đưa vào Báo cáo Chương 4.

**Nguồn đối chiếu:** đề `Báo Cáo Cuối Kỳ.docx`, các mục “Khởi động và kiểm thử”,
“Mở rộng” và bảng chấm điểm. Có 10 mục mở rộng trong danh sách/bảng điểm dù đoạn dẫn ghi 9.
Các hướng dẫn dưới đây không bảo đảm điểm số nếu chưa có kết quả thực tế và minh chứng.

**Quy trình chính:** Docker/Compose để chạy dịch vụ, trình duyệt để thao tác Keycloak/MinIO/Grafana,
`curl` kiểm HTTP/API và `dig` kiểm DNS. **Không cần cài Python trên host để làm phần B–C.**
Các công cụ Python của nhóm chỉ là hỗ trợ tùy chọn ở phần D, không phải yêu cầu bổ sung của Thầy.

Chạy lệnh từ gốc repo. Khối `bash` dùng Bash/zsh trên Linux/macOS hoặc Git Bash trên Windows;
PowerShell dùng khối `powershell` tương ứng. Với lệnh curl một dòng trên PowerShell, dùng `curl.exe`
để tránh alias `Invoke-WebRequest`. DNS có cách chạy `dig` ngay trong container.
Tài liệu dùng cổng và tài khoản demo mặc định; nếu `.env` đổi thì dùng giá trị thực tế.
Trên EC2, chạy lệnh qua SSH; mở UI từ máy cá nhân bằng Public IP/hostname đã cấu hình.

**Nghiệm thu:** Running không thay kiểm tra chức năng, HTTP 200 không thay kiểm tra JSON/file.
Chụp ảnh kết quả thực tế từng mục, không chụp mật khẩu/token. Phải thử lại trên EC2;
kiểm thử local không thay điều kiện Ubuntu/Public IP, image Docker Hub và báo cáo 5 chương/phụ lục.

---

## Phần A: Chuẩn Bị Và Khởi Động Cụm Trước Khi Test

Cần Docker Desktop ở chế độ Linux containers hoặc Docker Engine/Compose trên Ubuntu,
Git và trình duyệt. Máy mới cần Internet để pull image/build MinIO. Dùng nhánh tích hợp `develop`:

```bash
# Máy mới: clone rồi vào repo; nếu đã có repo thì vào đúng thư mục đang dùng.
git clone --branch develop --single-branch https://github.com/KwanFam26022005/Final-CloudComputing.git
cd Final-CloudComputing

# Kiểm tra Docker Engine/Compose hoạt động
docker info
docker compose version

# Tạo .env từ mẫu nếu chưa có; không ghi đè .env đã cấu hình.
# Bash/zsh:
if [ ! -f .env ]; then cp .env.example .env; fi

# Build Web/App/MinIO rồi chạy cả cụm; giữ nguyên dữ liệu hiện có.
docker compose config -q
docker compose build
docker compose up -d
docker compose ps --all
```

PowerShell: thay dòng tạo `.env` bằng `if (!(Test-Path .env)) { Copy-Item .env.example .env }`.
Các lệnh Docker/Git ở trên dùng giống nhau. Không cần `--no-cache` để chạy bình thường.
Compose gốc đã tích hợp build MinIO, volume Keycloak và cấu hình Bind9, không cần override.
Nếu dịch vụ còn khởi động, đọc `docker compose logs --tail 50 <service>` và kiểm lại chức năng khi sẵn sàng.

Chỉ khi chủ động muốn dừng cụm dự án mới dùng `docker compose stop`; không có bước bắt buộc
xóa container/volume trước khi test. Máy mới chưa có bucket/file MinIO từ máy thành viên khác.
**Kỳ vọng môi trường:** 9 loại server, cấu hình nhóm có 11 container vì thêm Node Exporter và Web replica.

---

## Phần B: 10 Bài Kiểm Thử Cơ Bản (5.0 Điểm)

### 1️⃣ Web Frontend Server (`web-frontend-server`)
```bash
curl -I http://localhost:8080/
curl -I http://localhost:8080/blog/
curl -s http://localhost:8080/
```
- **Kỳ vọng:** Trả về `HTTP/1.1 200 OK`, nội dung hiển thị `MyMiniCloud – Home` và `MyMiniCloud – Blog`.

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

# Cách 2: Query qua network alias db (cùng mục tiêu với lệnh mẫu trong đề)
docker run --rm --network cloud-net mariadb:11 sh -lc 'mariadb -h db -uroot -proot -e "USE minicloud; SHOW TABLES; SELECT * FROM notes;"'
```
- **Kỳ vọng:** Hiển thị bảng `notes` và bản ghi `Hello from MariaDB!`.

### 4️⃣ Authentication Identity Server (`authentication-identity-server`)
- **Căn cứ đề:** kiểm thử Auth Server — đăng nhập quản trị và tạo/kiểm tra user test.
- Mở `http://localhost:8081`, đăng nhập admin theo `.env`; mặc định demo là **`admin` / `admin`**.
- Trong **Manage realms**, chọn **`realm_52300107`** → **Users**, liệt kê/tìm `sv01` và `sv02`.
  Đây là realm MSSV phần Auth hiện có trong repo, không phải tên tài khoản đăng nhập.
- Vào **Clients**, kiểm tra `flask-app` là public client (Client authentication tắt),
  Direct Access Grants bật. Tài khoản mẫu phải enabled và không bị buộc đổi mật khẩu khi lấy token.
- **Kỳ vọng:** đăng nhập Admin Console được, thấy đúng realm, hai users và client.
  Máy mới import từ JSON; realm đã tồn tại trong volume không tự bị ghi đè khi sửa file import.
  Không xóa volume để ép import lại.

- Nếu chưa có user test, chọn **Add user**, nhập `sv01`, bật Enabled và lưu;
  vào **Credentials → Set password**, đặt mật khẩu demo và tắt Temporary.
  Không tạo trùng user đã được import. Kiểm việc cấp token tại Mở rộng 4.

### 5️⃣ Object Storage Server (`object-storage-server`)
- **Căn cứ đề:** kiểm thử Storage Server — tạo bucket, upload và tải file.
- Mở MinIO Console `http://localhost:9001`, đăng nhập theo `.env`;
  mặc định demo là **`minioadmin` / `minioadmin`**.
- Tạo bucket **`demo`** nếu chưa có; giữ private. Upload `web-frontend-server/html/index.html`
  vào gốc bucket, giữ tên **`index.html`**.
- Dùng Console tải lại file và đối chiếu nội dung với file nguồn.
- **Kỳ vọng:** thấy `demo/index.html`, tải thành công và nội dung khớp; không chỉ kiểm tra file có tên trong danh sách.
- Trên máy triển khai mới, bucket/file runtime không tự đi theo Git; cần tạo/upload hoặc chuyển dữ liệu có chủ đích.
  Compose gốc đã build MinIO từ Dockerfile, không cần ghép override. Xem [README Storage](../object-storage-server/README.md).

### 6️⃣ Internal DNS Server (`internal-dns-server`)
**Căn cứ đề:** kiểm thử Internal DNS — bản ghi Web trả về `10.10.10.10`.

```bash
# Kiểm tra cấu hình Bind9 trong container đang chạy
# Thành công: exit 0, không có lỗi cấu hình.
docker exec internal-dns-server named-checkconf /etc/bind/named.conf

# Query UDP từ host nếu có dig
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local A +noall +comments +answer

# Query TCP từ host
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local A +tcp +noall +comments +answer

# Không cần cài dig trên host/Windows: dùng dig có sẵn trong container DNS
docker exec internal-dns-server dig @127.0.0.1 web-frontend-server.cloud.local A +noall +comments +answer
docker exec internal-dns-server dig @127.0.0.1 web-frontend-server.cloud.local A +tcp +noall +comments +answer
```

- **Kỳ vọng:** query thành công, `status: NOERROR`, flags có `aa`, answer A của
  `web-frontend-server.cloud.local.` là **`10.10.10.10`** qua cả UDP/TCP.
- Chọn cách host hoặc container phù hợp môi trường; không cần chạy cả hai cách để lặp lại cùng phép thử.
  `dig` đúng chứng minh phân giải DNS, không thay kiểm thử ping/kết nối dịch vụ ở mục thông mạng.

### 7️⃣ Monitoring Node Exporter + Prometheus (`monitoring-prometheus-server`)
- Mở trình duyệt: `http://localhost:9090/targets`
- **Kỳ vọng:** Target `monitoring-node-exporter-server:9100` có trạng thái **`UP`** màu xanh lá.
- Chuyển sang tab **Graph** (`http://localhost:9090/graph`), nhập `node_cpu_seconds_total` và nhấn **Execute**.

### 8️⃣ Monitoring Grafana Dashboard (`monitoring-grafana-dashboard-server`)
- Mở trình duyệt: `http://localhost:3000`
- Đăng nhập: **`admin` / `admin`**
- Kiểm tra **Connections → Data sources**: Datasource `Prometheus` (`http://prometheus:9090`) đã được kết nối sẵn (hoặc nhấn *Save & test* báo xanh).
- Vào **Dashboards**, mở **Node Exporter Full** đã được provisioning từ repo.
  Nếu chưa có mới **New → Import → 1860 → Load → chọn Prometheus → Import**.
- **Kỳ vọng:** biểu đồ CPU/RAM/Network có dữ liệu, không chỉ thấy tên dashboard.

### 9️⃣ API Gateway Proxy Server (`api-gateway-proxy-server`)
```bash
curl -I http://localhost/
curl -s http://localhost/api/hello
curl -I http://localhost/auth/
```
- **Kỳ vọng:**
  - `/`: `HTTP/1.1 200 OK`
  - `/api/hello`: `{"message":"Hello from App Server!"}`
  - `/auth/`: theo đề, trả **302** đến trang đăng nhập Keycloak. Mở URL này bằng trình duyệt
    và kiểm cả đích redirect; 302 nhưng đến 404 chưa đạt. Không chỉ dựa vào `curl -I`.

### 🔟 Kiểm thử thông mạng nội bộ (`ping` giữa các server trên `cloud-net`)

**Điều kiện trước khi ping:** phải chạy cả cụm ở phần A, không chỉ ba service Auth/Storage/DNS.
Kiểm tra ngay trong thư mục repo:

```bash
docker compose ps --all
```

**Kỳ vọng:** đủ 11 service của cấu hình nhóm đang `Up/Running`, gồm cả DB, Node Exporter,
Prometheus và Grafana. Nếu thiếu hoặc đang dừng, khởi chạy các service đã khai báo rồi kiểm tra lại:

```bash
docker compose up -d
docker compose ps --all
```

Nếu `up` báo lỗi hoặc container `Exited/Restarting`, đọc log service đó và xử lý trước khi ping:

```bash
docker compose logs --tail 50 relational-database-server monitoring-prometheus-server monitoring-grafana-dashboard-server
```

Dùng container MinIO đã có `ping` để kiểm cùng các alias trong đề, không cần cài gói vào Gateway:

```bash
docker exec object-storage-server sh -c '
  for target in web app-server db keycloak minio prometheus grafana dns-server; do
    echo "=== PING $target ==="
    ping -c 3 "$target"
  done
'
```

- **Kỳ vọng:** đủ tám đích, mỗi đích `3 packets transmitted, 3 packets received, 0% packet loss`.
- Đây là cách chọn container nguồn của nhóm; yêu cầu đề là kiểm tra thông mạng giữa các server.
- Nếu gặp `ping: bad address 'db'`, `'prometheus'` hoặc `'grafana'`, trước hết kiểm tra service
  tương ứng đã chạy bằng `docker compose ps --all`. Trong lần kiểm thử local, ba tên này chưa có
  vì ba container chưa được khởi chạy; sau khi chạy service, ping cả ba đạt 0% packet loss.
- `bad address` nghĩa là tên chưa phân giải được trong container nguồn, chưa đủ căn cứ kết luận
  Bind9 hỏng. Các alias `db/prometheus/grafana` trong bước này do mạng Docker cung cấp;
  khác với bản ghi `*.cloud.local` kiểm bằng `dig` ở B.6/C.6. Không sửa zone chỉ để xử lý container chưa chạy.
- Nếu các service đã Up mà tên vẫn không phân giải, kiểm tra chúng có cùng mạng `cloud-net`
  và đúng alias trong Compose, thay vì tự đổi bản ghi DNS. Lỗi kết nối khi tên đã phân giải cần kiểm tra riêng.

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

### 🌟 Mở rộng 3: Database `studentdb` + Bảng `students` (`0.5đ`)

**Yêu cầu đề:** đúng schema và ít nhất 3 bản ghi. CRUD/kết nối Flask đọc DB là phần
**tùy chọn của đề**, nhóm chọn làm thêm; không coi chúng là điều kiện bắt buộc để đạt riêng mục mở rộng 3.
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

### 🌟 Mở rộng 4: Realm theo MSSV + `flask-app` + `sv01`/`sv02` + `/secure` (`0.5đ`)

**Theo đề:** tạo realm theo MSSV, hai user, public client, lấy token và truy cập `/secure`.
Repo hiện dùng **`realm_52300107`**, hai user `sv01`/`sv02`, client `flask-app`.
Xem UI tại phần B.4; nếu tạo thủ công, bật Direct Access Grants và đặt mật khẩu user không Temporary.
Mật khẩu dưới đây là tài khoản demo trong JSON import; nếu đã đổi thì dùng mật khẩu thực tế.

**Bash/zsh/Git Bash:** lấy token bằng curl, giữ trong biến, rồi gọi App và Gateway.
`sed` chỉ lấy trường token từ JSON, không cần Python/jq trên host. Chạy nguyên khối:

```bash
(
  set -eu
  # Tài khoản sv01, không echo token hoặc bật set -x.
  TOKEN=$(curl -fsS --max-time 20 -X POST \
    "http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=flask-app" \
    --data-urlencode "username=sv01" \
    --data-urlencode "password=sv01pass" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "scope=openid profile" \
    | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  if [ -z "$TOKEN" ]; then echo "FAIL: khong lay duoc token"; exit 1; fi

  # Trực tiếp App, rồi qua Gateway
  curl -sS --max-time 20 -H "Authorization: Bearer $TOKEN" \
    -w '\nHTTP %{http_code}\n' http://localhost:8085/secure
  curl -sS --max-time 20 -H "Authorization: Bearer $TOKEN" \
    -w '\nHTTP %{http_code}\n' http://localhost/api/secure
  unset TOKEN
)
```

**PowerShell:** chạy khối tương đương sau, không dán cú pháp biến của Bash:

```powershell
$token = $null
try {
    $response = Invoke-RestMethod -Method Post -TimeoutSec 20 `
        -Uri "http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token" `
        -Body @{ client_id="flask-app"; username="sv01"; password="sv01pass"; grant_type="password"; scope="openid profile" } `
        -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    $token = $response.access_token
    if (!$token) { throw "Khong lay duoc token" }
    foreach ($url in @("http://localhost:8085/secure", "http://localhost/api/secure")) {
        $result = Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 -Uri $url `
            -Headers @{ Authorization="Bearer $token" } -ErrorAction Stop
        Write-Host "HTTP $($result.StatusCode)"
        Write-Host $result.Content
    }
} finally {
    $token = $null
    $response = $null
}
```

**Kỳ vọng:** cả hai API trả HTTP `200`, JSON có `message`, `preferred_username` và `realm` như sau
(có thể có thêm `client_id`):

```json
{"message":"Secure resource OK","preferred_username":"sv01","realm":"realm_52300107"}
```

Lặp lại với `username=sv02`, `password=sv02pass`; kỳ vọng `preferred_username` là `sv02`, realm giữ nguyên.
Nếu trực tiếp App đạt nhưng Gateway lỗi, ghi riêng lỗi tích hợp proxy. Nếu lấy token thất bại, dừng để
kiểm tra realm/client/user, không chụp token thật. Mẫu JWT trong đề kiểm chữ ký, issuer và audience;
200 với token hợp lệ chưa chứng minh App từ chối được mọi token không hợp lệ.

### 🌟 Mở rộng 5: MinIO `profile-pics` (avatar public) và `documents` (PDF) (`0.5đ`)

**Theo đề:** tạo bucket, upload `avatar.jpg`, mở URL public; tạo `documents` và upload PDF báo cáo.

1. Đăng nhập MinIO Console `http://localhost:9001` bằng tài khoản quản trị đã cấu hình.
2. Tạo **`profile-pics`** nếu chưa có, upload ảnh đại diện JPEG thật tên **`avatar.jpg`** vào gốc bucket.
3. Cấp quyền đọc public cho avatar. Nếu Console có mục policy, dùng Custom policy cho riêng object
   như bên dưới. Bản Console chỉ có Object Browser có thể không có mục quản trị policy;
   khi đó dùng cách gọi S3 API bằng curl ở phần D.1 trước khi kiểm URL.
4. Mở `http://localhost:9000/profile-pics/avatar.jpg` trong cửa sổ ẩn danh: ảnh phải hiển thị không cần đăng nhập.
5. Tạo **`documents`**, upload **PDF báo cáo cuối kỳ chính thức**. Mở bucket trong Console,
   tải PDF về và kiểm nội dung; chụp ảnh file xuất hiện trong bucket. PDF demo chưa thay báo cáo thật.

Policy mẫu cho bucket `profile-pics` mới (biện pháp nhóm chỉ public đúng avatar;
đề chỉ yêu cầu URL ảnh đọc public, không bắt public cả bucket):

```json
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::profile-pics/avatar.jpg"]}]}
```

Kiểm URL không cần tài khoản:

```bash
curl -sS -o /dev/null -w 'Avatar HTTP %{http_code}\n' http://localhost:9000/profile-pics/avatar.jpg
```

PowerShell: mở URL ảnh trong trình duyệt hoặc dùng `curl.exe -sS -o NUL -w "Avatar HTTP %{http_code}" http://localhost:9000/profile-pics/avatar.jpg`.
**Kỳ vọng:** HTTP `200` và trình duyệt hiển thị đúng ảnh, không chỉ HTTP 200 với nội dung khác.
Giữ `documents` private là quy ước kỹ thuật nhóm; kiểm tải PDF khi đăng nhập.
Dữ liệu MinIO không tự theo Git sang EC2: cần tạo/upload hoặc chuyển dữ liệu có chủ đích rồi kiểm lại.

### 🌟 Mở rộng 6: Internal DNS thêm bản ghi `app-backend`, `minio`, `keycloak` (`0.5đ`)
**Căn cứ đề:** Mở rộng 6 — thêm bản ghi App và các bản ghi MinIO/Keycloak, kiểm tra phân giải.
Chỉ restart khi vừa thay cấu hình; không cần restart hoặc sửa lại DNS đã đạt và không đổi cấu hình.

```bash
# Kiểm tra cú pháp trước; nếu có lỗi thì dừng tại đây để xử lý.
docker exec internal-dns-server named-checkconf /etc/bind/named.conf

# Chỉ chạy dòng này sau khi vừa cập nhật cấu hình DNS và kiểm cú pháp thành công:
# docker compose restart internal-dns-server

# Dùng dig có sẵn trong container, không cần cài dig trên host.
# Kiểm cả bốn record qua UDP và TCP.
docker exec internal-dns-server sh -c '
  for mode in +notcp +tcp; do
    for host in web-frontend-server app-backend minio keycloak; do
      echo "=== $host.cloud.local $mode ==="
      dig @127.0.0.1 "$host.cloud.local" A "$mode" +time=2 +tries=1 +noall +comments +answer
    done
  done
'
```

**Kỳ vọng:** 8/8 query `NOERROR`, flags có `aa`, answer A đúng bảng:

| Tên | IP mong đợi trong cấu hình nhóm |
| --- | --- |
| `web-frontend-server.cloud.local` | `10.10.10.10` |
| `app-backend.cloud.local` | `10.10.10.20` |
| `minio.cloud.local` | `10.10.10.30` |
| `keycloak.cloud.local` | `10.10.10.40` |

Đề ấn định IP Web/App; IP `.30`/`.40` của MinIO/Keycloak là lựa chọn cấu hình nhóm.
Script vòng lặp trên hỗ trợ quan sát; phải đọc đủ trạng thái và answer của từng query,
không dùng riêng exit code của lệnh cuối để kết luận 8/8. Ping/kết nối dịch vụ kiểm riêng ở phần B.10.

### 🌟 Mở rộng 7: Prometheus Scrape Target `web-frontend-server:80` đạt `UP` (`0.5đ`)
- Mở `http://localhost:9090/targets`.
- **Kỳ vọng:** job `node` có `monitoring-node-exporter-server:9100` UP; job `web` có
  `web-frontend-server:80` UP. Repo giám sát thêm replica `web-frontend-server2:80`, cũng cần UP.
- Mở query `web_frontend_up` để thấy metric Web, không chỉ kiểm HTTP trang chủ.

### 🌟 Mở rộng 8: Grafana Dashboard cá nhân `System Health of <MSSV>` (`0.5đ`)
- Mở `http://localhost:3000` → **Dashboards**.
- Mở dashboard **`System Health of 52300140`** đã có trong repo (MSSV của Nhật, phụ trách Monitoring).
- Kiểm tra và chụp ảnh đủ ba biểu đồ **CPU Usage (%)**, **Memory Usage (%)**, **Network Traffic** có dữ liệu.
  Không tự đổi dashboard sang MSSV Hùng hoặc coi dashboard trống là đạt.

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


---

## Phần D: Biện Pháp Cấu Hình Và Công Cụ Hỗ Trợ Của Nhóm

Phần này là cách triển khai/kiểm tra thêm của nhóm, **không phải yêu cầu điểm bổ sung của đề**.

### D.1. Cấp quyền avatar khi Console không có mục policy — dùng curl

Chỉ dùng policy mẫu ở C.5 cho **bucket mới chưa có policy tùy chỉnh**. Nếu đã có policy riêng,
người quản trị cần giữ các quyền hiện có khi bổ sung GET avatar; không ghi đè nguyên policy bằng mẫu.
Cần curl có `--aws-sigv4` (kiểm bằng `curl --help all`); không cần cài Python hoặc MinIO Client.
Lệnh dưới dùng credential demo; nếu `.env` đổi, nhập credential quản trị tương ứng.
Chạy trên máy host/SSH vào EC2, sau khi bucket và ảnh đã tồn tại:

```bash
curl -sS --max-time 20 --aws-sigv4 'aws:amz:us-east-1:s3' \
  --user 'minioadmin:minioadmin' -X PUT 'http://localhost:9000/profile-pics?policy' \
  -H 'Content-Type: application/json' \
  --data-binary '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::profile-pics/avatar.jpg"]}]}' \
  -w '\nPolicy HTTP %{http_code}\n'
```

Trên PowerShell, tạo file policy tạm ngoài repo rồi gọi API:

```powershell
$policyFile = Join-Path $env:TEMP "n07-avatar-policy.json"
Set-Content -LiteralPath $policyFile -Encoding Ascii -Value '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::profile-pics/avatar.jpg"]}]}'
curl.exe -sS --max-time 20 --aws-sigv4 "aws:amz:us-east-1:s3" `
  --user "minioadmin:minioadmin" -X PUT "http://localhost:9000/profile-pics?policy" `
  -H "Content-Type: application/json" --data-binary "@$policyFile" `
  -w "Policy HTTP %{http_code}"
```

**Kỳ vọng:** PUT policy trả `204`; sau đó thực hiện lại C.5, GET avatar phải 200 và hiển thị ảnh thật.
Đây là thao tác sửa quyền bucket, không phải lệnh chỉ đọc. Không đặt public bucket `documents`.
Nguồn kỹ thuật: [curl AWS SigV4](https://curl.se/docs/manpage.html#--aws-sigv4),
[S3 PutBucketPolicy](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketPolicy.html).
Sau khi chạy cần kiểm GET trên chính môi trường triển khai; không coi việc tài liệu có lệnh là đã cấp quyền thành công.

### D.2. Kiểm tra tự động tùy chọn bằng Python

Chỉ dùng nếu muốn kiểm thêm; các bước B–C không phụ thuộc phần này.
Công cụ Auth dùng Python 3 standard library; công cụ Storage cần SDK trong venv.
Xem [README Auth](../authentication-identity-server/README.md) và [README Storage](../object-storage-server/README.md).

```bash
python3 authentication-identity-server/verify_oidc.py
python3 authentication-identity-server/verify_secure.py --app-url http://localhost/api/secure

python3 -m venv object-storage-server/.venv
object-storage-server/.venv/bin/python -m pip install -r object-storage-server/requirements-client.txt
object-storage-server/.venv/bin/python object-storage-server/verify_storage.py --all-pdfs
```

PowerShell: dùng `py -3` thay `python3`, và `.venv/Scripts/python.exe` thay `.venv/bin/python`.
Nếu muốn dùng script policy Python đã có thay cho D.1, đọc README Storage trước khi chạy `set_avatar_public.py --apply`.
Script Storage kiểm HTML/JPEG/PDF, unsigned/signed/tampered; không tự xác nhận PDF là báo cáo cuối kỳ.
Script Auth kiểm token/UserInfo và năm ca `/secure`; chưa bao phủ từ chối sai issuer/audience/hết hạn.
Không dùng việc script kết thúc để tự nhận đủ điểm hoặc thay minh chứng UI.

### D.3. Script cũ và cách ghi kết quả

Quy trình chính để thành viên mới chạy là phần A–C ở tài liệu này.
Các script `scripts/verify-base.*` và `scripts/verify-extended.*` chưa được sửa trong gói tài liệu này:
chúng còn realm mẫu `realm_sv001`, có thể thiếu mục Storage/Grafana hoặc chỉ in kết quả quan sát.
Không chạy nguyên script cũ để nghiệm thu realm `realm_52300107`; dùng lệnh đúng ở C.4.
Không dùng việc script kết thúc để tự nhận đủ điểm.

Ghi từng mục: **ĐẠT** khi đủ bằng chứng, **CHƯA ĐẠT** khi chạy ra kết quả sai,
**CHƯA KIỂM THỬ** khi chưa chạy được. Nếu `/auth/` chuyển đến 404 hoặc App nhận JWT sai issuer/audience,
ghi lỗi và bàn giao đúng module; không đổi kỳ vọng để biến kết quả thành PASS.
Sau khi sửa code phải kiểm lại trên commit mới.
