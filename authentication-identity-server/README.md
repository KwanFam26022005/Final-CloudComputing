# 🔐 4. Authentication & Identity Server (`authentication-identity-server`)

> **Thành viên phụ trách:** Thành viên 3 (Security, Storage & DNS Lead)  
> **Container Name:** `authentication-identity-server` (Port `8081:8080`)  
> **Network Aliases (`cloud-net`):** `keycloak`, `auth`, `keycloak.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng hệ thống Quản lý Định danh và Truy cập tập trung (Identity Provider - IdP / Single Sign-On tương tự AWS IAM Identity Center / Amazon Cognito) sử dụng **Keycloak** theo giao thức **OpenID Connect (OIDC)**.

## 2. Tự Động Khởi Tạo Realm Mở Rộng (`import/realm-export.json`)
Container Keycloak được cấu hình chạy với cờ `start-dev --import-realm`, tự động nạp file `import/realm-export.json` khi khởi động:
- **Realm cá nhân thành viên 3:** `realm_52300107` (Hùng, MSSV `52300107`). Chưa tự chọn làm realm đại diện toàn nhóm.
- **Client:** `flask-app` (`Access Type: public`, `Direct Access Grants: Enabled`)
- **2 Users tạo sẵn:**
  - `sv01` (Password: `sv01pass`)
  - `sv02` (Password: `sv02pass`)
- **Tài khoản Admin mặc định:** `admin` / `admin` tại `http://localhost:8081`.
- **Audience Mapper:** `backend-audience`, loại `oidc-audience-mapper`, custom audience `myapp`; access token/introspection bật, ID token/lightweight/userinfo tắt. Giá trị này khớp `OIDC_AUDIENCE=myapp` đang khai báo cho App.

Keycloak import lúc khởi động bỏ qua realm đã tồn tại. Thay file JSON không tự
cập nhật realm đang chạy. Mapper trên đã được cấu hình bằng Admin Console và
được đồng bộ vào JSON để tái lập khi khởi tạo realm mới; không cần restart hoặc
xóa dữ liệu để áp dụng lại vào runtime đã cấu hình.

## 3. Lệnh Kiểm Thử Lấy Token & Gọi `/secure` (Mở rộng #4)

Chạy từ gốc repository để kiểm tra hai users, không in/lưu token hoặc mật khẩu:

```bash
python3 authentication-identity-server/verify_oidc.py --audience myapp
```

Script yêu cầu Token/UserInfo HTTP 200, đúng danh tính/issuer/client, access token
có audience `myapp`. Phần đọc JWT claims phục vụ đối chiếu cấu hình; script không
thay thế kiểm thử xác thực chữ ký/issuer/audience trong Flask `/secure`.

Thông tin bàn giao cho thành viên 2:

- Client ID: `flask-app`; expected audience: `myapp`.
- Issuer local: `http://localhost:8081/realms/realm_52300107`.
- Token endpoint: `http://localhost:8081/realms/realm_52300107/protocol/openid-connect/token`.
- JWKS nội bộ: `http://authentication-identity-server:8080/realms/realm_52300107/protocol/openid-connect/certs`.
- Khi App/Gateway sẵn sàng, kiểm tra token hợp lệ gọi `/secure` hoặc `/api/secure`
  được HTTP 200 và đúng user; thiếu/sai/hết hạn token bị từ chối theo chuẩn nhóm.

Phần App hiện còn issuer mặc định realm master và tắt verify issuer/audience;
thành viên 2 xử lý code/cấu hình tương ứng. Phần `/auth/` qua Gateway cần phối hợp người điều phối. Volume Keycloak đã có
override module và được kiểm thử local; cần giữ override khi tích hợp Compose. Không ghi tích hợp hoàn tất chỉ
từ kết quả cấp token hoặc UserInfo.

Khi App sẵn sàng, kiểm tra tích hợp trực tiếp bằng công cụ của module Auth:

```bash
python3 authentication-identity-server/verify_secure.py
```

Script dùng token mới cho sv01/sv02 để gọi `http://localhost:8085/secure`, kiểm tra
HTTP200 và đúng username; thiếu token, token sai cấu trúc hoặc sửa chữ ký phải401.
Các kiểm tra issuer/audience/hết hạn phía App và đường qua Gateway vẫn cần nghiệm
thu riêng. Script không sửa App hoặc cấu hình runtime, không in/lưu token.

## 4. Chuẩn bị lưu bền: sao lưu dữ liệu lab trước khi thay mount

Căn cứ GV-02: volume khi cần giữ dữ liệu. Không đổi realm/user/client hoặc Compose
chung. Trước khi chuyển dữ liệu dev-file sang volume, tạo bản sao nguội:

```bash
python3 authentication-identity-server/backup_data.py --output docs/shared/backups
```

Script chỉ nhắm container authentication-identity-server, kiểm tra thư mục đích
đã được Git exclude và không có file tracked, tạo thư mục backup mới, dừng Keycloak
với thời gian chờ60giây, sao chép /opt/keycloak/data, kiểm H2 không rỗng và ghi hash,
rồi gọi start lại chính container trong finally kể cả khi sao chép lỗi. Code stop0
hoặc143 được chấp nhận; OOM/kill cưỡng bức không được đánh dấu backup hoàn tất.
Không xóa container/volume, không migrate hoặc thay mount. Auth gián đoạn ngắn;
không thực hiện đồng thời với thao tác quản trị/ghi dữ liệu khác.

Backup chứa dữ liệu nhạy cảm, giữ local và không commit/upload. Thư mục shared là
vị trí riêng của clone hiện tại; clone khác phải cấu hình exclude trước. Nếu lệnh
báo lỗi, giữ container cũ và kiểm tra trạng thái, không tự tạo lại hoặc xóa dữ liệu.
Backup file + hash chưa chứng minh khôi phục được; cần thử khôi phục và kiểm tra
realm/user/client sau bước chuyển volume. Sau khi start, kiểm tra readiness bằng
verify_oidc.py; phải chờ dịch vụ sẵn sàng, không suy ra start thành công là chức
năng Auth đã đạt. Quy trình chuyển volume bên dưới đã được kiểm thử trên local.

Tham khảo chính thức: https://www.keycloak.org/server/containers và
https://www.keycloak.org/server/importExport . File import không tự ghi đè realm
đã tồn tại và không thay thế đầy đủ database backup.

### Chuẩn bị volume từ bản sao lưu (chưa chuyển container)

```bash
python3 authentication-identity-server/prepare_volume.py docs/shared/backups/<thu-muc-backup>
```

Tạo mới volume n07-keycloak-data, dùng image MinIO/Alpine đã build local làm công cụ
copy với mạng tắt, không chạy server MinIO. Không pull image. Bản backup được mount
read-only; dữ liệu đích thuộc UID1000, hash từng file phải khớp manifest. Nếu volume
đã tồn tại thì từ chối ghi đè, không xóa tự động. Nếu lỗi giữa chừng giữ volume để
kiểm tra; không chạy Compose persistence khi chưa xác nhận. Container Keycloak hiện
hữu vẫn dùng dữ liệu cũ, không bị thay mount/dừng bởi bước này.

Image công cụ mặc định được build từ module Storage; nếu chỉ checkout task Auth,
có thể chỉ định `--helper-image <image-local>` có sẵn các lệnh
`sh`, `cp`, `chown`, `find`, `sha256sum`. Không cần module Storage để khởi tạo
Keycloak mới theo mục bên dưới. Không dùng `prepare_volume.py` để ghi đè volume cũ.

compose.persistence.yml khai báo volume external và giữ import mount từ Compose gốc.
Đây là cấu hình bổ sung module Auth theo GV-02, chưa sửa Compose chung. Không áp dụng
cho container có dữ liệu trước khi chốt chuyển snapshot và kiểm tra restore. Thay đổi
quản trị sau thời điểm backup không nằm trong snapshot; nếu có thay đổi cần backup
mới và phương án chuyển lại, không ghi đè volume đang dùng. Các phiên/token tạm có
thể cần đăng nhập lại sau khôi phục. Đây là dev-file một máy cho lab, không phải
cấu hình database production/HA hoặc bằng chứng đã kiểm thử EC2.

### Áp dụng volume đã phục hồi (sau khi đối chiếu snapshot)

Chỉ thực hiện sau khi prepare_volume.py báo hash khớp, đã có backup và không có
thay đổi quản trị cần giữ sau thời điểm backup. Dùng cùng image hiện chạy; kiểm tra
image local trước khi áp dụng, không pull latest mới trong lúc chuyển H2.

```bash
docker compose -f docker-compose.yml -f authentication-identity-server/compose.persistence.yml up -d --no-deps --no-build --pull never authentication-identity-server
docker compose -f docker-compose.yml -f authentication-identity-server/compose.persistence.yml ps authentication-identity-server
```

Compose tạo lại riêng Auth để gắn volume; có gián đoạn ngắn. Từ bước này luôn ghép
compose.persistence.yml khi quản lý Auth, nếu chạy lại bằng Compose gốc riêng sẽ
làm mất mount khỏi cấu hình container. Không dùng down -v hoặc xóa volume.
Sau khởi động cần xác minh mount thực tế, verify_oidc.py, Admin Console và kiểm tra
lại sau recreate. Running chưa đủ để chốt lưu bền. Nếu startup lỗi, giữ volume và
backup; đọc log có lọc bí mật trước, không xóa/reset để chữa lỗi. Không rollback
bằng cách chỉ bỏ override vì container cũ đã bị thay thế và data không còn ở lớp
writable cũ. Chưa nghiệm thu cho tới khi kiểm tra sau chuyển thực sự đạt.

Kết quả local ngày28/10/2026: backup/restore và force-recreate với volume đã kiểm
đạt; bộ khóa ký giữ nguyên, sv01/sv02 Token/UserInfo200 và claims/audience đúng sau
recreate. Minh chứng riêng được giữ local, chưa nghiệm thu EC2. Luôn ghép override
persistence khi chạy Auth; không dùng lại base Compose riêng cho service này.

### Khởi tạo mới trên máy chưa có dữ liệu Keycloak

Chỉ dùng khi thực sự khởi tạo mới, không dùng để thay thế dữ liệu cần bảo toàn:

```bash
docker volume create n07-keycloak-data
docker compose -f docker-compose.yml -f authentication-identity-server/compose.persistence.yml up -d --no-deps authentication-identity-server
python3 authentication-identity-server/verify_oidc.py --audience myapp
```

Volume external cần tồn tại trước khi Compose chạy. Realm import tạo dữ liệu mẫu
trong database mới; không coi đó là phục hồi database. Không xóa volume nếu realm
không khớp mong đợi. Bộ dữ liệu và mật khẩu có sẵn trong import chỉ dùng cho lab.

Các mã GV-* trong README là mã truy vết local: GV-02 tương ứng yêu cầu kỹ thuật
chung về volume, GV-MR04 tương ứng phần mở rộng Keycloak của đề Thầy. Không cần
file checklist hoặc tài liệu shared riêng để chạy các lệnh trong module này.
