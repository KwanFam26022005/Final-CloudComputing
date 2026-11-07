# 4. Authentication & Identity — Keycloak

Thành viên 3 — Hùng `52300107`. Container `authentication-identity-server`,
cổng `8081:8080`, alias `keycloak`, `auth`, `keycloak.cloud.local`.

## 1. Yêu cầu và cấu hình được sử dụng

- **Cơ bản 4:** đăng nhập quản trị và tạo/kiểm tra user test.
- **Mở rộng 4:** realm theo MSSV, hai user `sv01`, `sv02`, public client
  `flask-app`, lấy access token và gọi `/secure`.
- File `import/realm-export.json`: realm `realm_52300107`, Direct Access Grants,
  hai user demo và audience mapper `backend-audience` cho audience `myapp`.
- Compose gốc mount import read-only và named volume `n07-keycloak-data` tại
  `/opt/keycloak/data`. Chạy `docker compose up -d` không cần file override.

Tài khoản lab mặc định: quản trị `admin` / `admin`; hai user `sv01` / `sv01pass`
và `sv02` / `sv02pass`. Cấu hình môi trường có thể thay tài khoản quản trị.
Import chỉ nạp realm chưa có; sửa JSON không tự cập nhật realm đã tồn tại.

## 2. Demo yêu cầu của đề

1. Mở `http://localhost:8081`, đăng nhập quản trị, chọn `realm_52300107`.
2. Mở **Users** để thấy `sv01`, `sv02`; mở **Clients → flask-app** để kiểm public
   client và Direct Access Grants.
3. Khi App/Gateway của nhóm đã chạy, từ gốc repo chạy một trong hai lệnh:

```bash
bash scripts/verify-task4.sh
```

```powershell
.\scripts\verify-task4.ps1
```

Kỳ vọng: hai user lấy token/UserInfo đúng danh tính; `/secure` trực tiếp và
`/api/secure` qua Gateway trả đúng user; thiếu token, token sai cấu trúc hoặc
sửa chữ ký bị401. Script không in/lưu token hoặc mật khẩu.

**Tác dụng:** xác thực tập trung; App nhận danh tính qua access token thay vì
lưu và kiểm tra mật khẩu của sinh viên trong App.

## 3. Cải tiến giữ lại: lưu dữ liệu qua lần tạo lại container

**Tác dụng:** thay container không làm mất realm/user/client và khóa ký token.
Đây là sử dụng volume theo yêu cầu kỹ thuật chung, không phải mục điểm mới.

Demo từ gốc repo, chọn đúng lệnh cho máy đang dùng:

```bash
bash scripts/verify-task4.sh --recreate-auth
```

```powershell
.\scripts\verify-task4.ps1 -RecreateAuth
```

Có gián đoạn Auth ngắn. Script chỉ recreate Auth, giữ image hiện có bằng
`--pull never`, giữ volume, không xóa dữ liệu. Nó đối chiếu container ID thay đổi,
image/volume/JWKS giữ nguyên, rồi lấy token cho hai user sau khi sẵn sàng.
Kỳ vọng `SUMMARY TASK4: FAIL=0`; mở lại Users trên Console vẫn thấy dữ liệu.

## 4. Công cụ kiểm thử còn sử dụng

| File | Dùng ở đâu / kiểm gì |
| --- | --- |
| `verify_oidc.py` | Task4: Token/UserInfo hai user, issuer/client và audience nếu yêu cầu. |
| `verify_secure.py` | Task4: token gọi App/Gateway, so danh tính và kiểm các ca401. |
| `import/realm-export.json` | Compose import cấu hình ban đầu trên máy mới. |

Python3 là đủ, không cần SDK ngoài. Có thể dùng riêng:

```bash
python3 authentication-identity-server/verify_oidc.py --audience myapp
python3 authentication-identity-server/verify_secure.py --app-url http://localhost/api/secure
```

Đọc JWT claims trong verifier chỉ đối chiếu cấu hình, không thay kiểm chữ ký ở
App. Script chưa kiểm token hết hạn/sai issuer/sai audience được App từ chối.
Phần kiểm issuer/audience phía App và proxy `/auth/` thuộc thành viên 2/1, không
sửa trong module này; không nhận SSO/browser login đã hoàn tất từ `/secure`200.

## 5. Hợp đồng tích hợp và giới hạn demo

- Client ID `flask-app`; expected audience `myapp`.
- Issuer local `http://localhost:8081/realms/realm_52300107`.
- JWKS nội bộ `http://authentication-identity-server:8080/realms/realm_52300107/protocol/openid-connect/certs`.
- `--auth-url` và `--app-url` chọn endpoint khi môi trường đổi; `--help` liệt kê
  tham số. Trên EC2 phải thống nhất hostname/issuer/redirect URI thực tế với nhóm.

Demo trên máy local không thay bằng chứng EC2. Named volume lưu dữ liệu đang
chạy, không phải hệ thống backup/HA; các công cụ di chuyển snapshot của lần
chuyển dữ liệu cũ đã được bỏ khỏi gói triển khai hiện tại.

## 6. Truy cập trực tiếp trên local và EC2

Compose lab không đặt `KC_HOSTNAME`, giữ `KC_HOSTNAME_STRICT=false` và
`KC_HTTP_ENABLED=true`. Keycloak tạo URL theo địa chỉ request: mở
`http://localhost:8081` trên local hoặc `http://<PUBLIC_IP>:8081` trên EC2.
Không cần ghi IP thật vào source. Biến `KC_HOSTNAME` trong `.env` cũ không còn
được Compose này truyền vào container. Muốn dùng hostname cố định khi triển khai
HTTPS, cần khai báo lại nó trong environment của service Auth.

Khi cập nhật container đang chạy, kiểm tra mount dữ liệu trước:

```bash
docker inspect authentication-identity-server --format '{{range .Mounts}}{{if eq .Destination "/opt/keycloak/data"}}type={{.Type}} name={{.Name}} rw={{.RW}}{{end}}{{end}}'
```

Chỉ tiếp tục khi đúng volume dữ liệu đang dùng (`n07-keycloak-data`, RW). Từ gốc
repo, tạo lại riêng Auth, giữ image và volume; có gián đoạn đăng nhập ngắn:

```bash
docker compose up -d --no-deps --no-build --pull never --force-recreate authentication-identity-server
```

Kiểm tra `Location` khi gọi `/` bằng địa chỉ truy cập thực tế, sau đó mở Console
và đăng nhập. HTTP302 đúng địa chỉ chưa chứng minh đăng nhập hoặc `/secure` đạt.

### Phân biệt hostname với lỗi “HTTPS required”

`KC_HTTP_ENABLED=true` mở HTTP listener; **Require SSL** của mỗi realm là chính
sách riêng. File import chỉ cấu hình `realm_52300107` với `sslRequired=none`;
nó không đổi chính sách realm quản trị `master`, và không ghi đè realm đã có.

Nếu `master` dùng **External requests**, truy cập HTTP qua Public IP có thể bị
chặn. Để vào Console kiểm tra, chạy SSH tunnel trên máy cá nhân (thay key/IP bằng
thông tin của môi trường, giữ terminal mở):

```bash
ssh -i /path/to/key.pem -o ExitOnForwardFailure=yes -N -L 127.0.0.1:18081:127.0.0.1:8081 ubuntu@<PUBLIC_IP>
```

Mở `http://localhost:18081/admin/`, chọn realm `master` → **Realm settings →
General → Require SSL**. Chỉ khi demo HTTP public tạm thời của lab mới chọn
**None → Save**, tải lại để xác nhận rồi thử đăng nhập public trong cửa sổ ẩn
danh. Thiết lập đã lưu nằm trong dữ liệu Keycloak, được giữ qua restart/recreate
khi giữ volume; máy mới với dữ liệu mới cần cấu hình lại. Commit này không tự
động tắt SSL của `master` khi startup.

`None` cho phép truyền mật khẩu/token qua HTTP public không có mã hóa TLS.
Triển khai lâu dài cần HTTPS, hostname cố định và chính sách SSL phù hợp; chế độ
hostname động của lab tin cậy Host header nên cần giới hạn nguồn truy cập.
Kiểm thử token và App phải dùng issuer nhất quán; proxy `/auth/` cần phối hợp
thành viên 1, kiểm issuer/audience phía App thuộc thành viên 2.

Tham khảo: [Hostname](https://www.keycloak.org/server/hostname),
[SSL theo realm](https://www.keycloak.org/docs/26.4.7/server_admin/index.html),
[Import realm](https://www.keycloak.org/server/importExport).
