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
