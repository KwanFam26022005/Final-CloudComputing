# 5. Object Storage — MinIO

Thành viên 3 — Hùng `52300107`. Container `object-storage-server`;
S3 API `http://localhost:9000`, Console `http://localhost:9001`.
Alias `minio`, `storage`, `minio.cloud.local`; dữ liệu ở `./object-storage-server/data`.
Tài khoản quản trị lab mặc định `minioadmin` / `minioadmin`, hoặc giá trị trong
môi trường Compose của máy triển khai.

## 1. Phần theo đề và phần cải tiến giữ lại

| Phần | Nội dung dùng để demo | Tác dụng |
| --- | --- | --- |
| Cơ bản5 | Bucket `demo`, upload/download `index.html` từ source Web. | Lưu và truy xuất object. |
| Mở rộng5 | `profile-pics/avatar.jpg` đọc public; `documents` có PDF báo cáo. | Bucket, object, endpoint và policy public/private. |
| Cải tiến | Console có Bucket policy, Policies và Users. | Thao tác quản trị quyền ngay trên giao diện. |
| Cải tiến | User chỉ đọc theo policy. | Xem tài liệu nhưng không sửa/xóa hoặc quản trị. |
| Cải tiến | PDF private, chia sẻ bằng link ký có thời hạn. | Chia sẻ tạm thời mà không public toàn bộ báo cáo. |
| Cải tiến | Logs và policy diagnostics. | Xem log server để chẩn đoán mà không cấp quyền sửa dữ liệu. |

Đề không bắt buộc readonly user hoặc link ký; đây không phải mục điểm mới.
Nội dung PDF đúng báo cáo thật cần mở xem, không kết luận chỉ từ tên file.

## 2. Khởi chạy và công cụ dùng thật

Compose gốc tự build source server `RELEASE.2025-10-15T17-29-55Z`, nhúng Console
quản trị chính thức `v1.7.6`. Đây là build tùy chỉnh của nhóm, giữ server hiện tại;
Go kiểm checksum module và image kèm license. Không cần override hay image bên thứ ba.

```bash
docker compose up -d --build --no-deps object-storage-server
```

Lệnh dùng được trong Bash/PowerShell. Giữ nguyên data mount, không xóa dữ liệu
để cập nhật image. Tải lại cứng hoặc mở ẩn danh nếu trình duyệt còn cache UI cũ.
Sidebar đã thu gọn còn Object Browser, Buckets, Policies, Users, Logs và Sign Out.
Build áp dụng `trim_console_menu.py` lên bản copy Console v1.7.6 và đổi tên asset
để tránh cache giao diện cũ. Đây là thay đổi menu, không thay policy hoặc quyền API.

Cài SDK một lần để chạy test và tạo link tải PDF:

```bash
python3 -m venv object-storage-server/.venv
object-storage-server/.venv/bin/python -m pip install -r object-storage-server/requirements-client.txt
```

```powershell
py -3 -m venv object-storage-server/.venv
.\object-storage-server\.venv\Scripts\python.exe -m pip install -r .\object-storage-server\requirements-client.txt
```

## 3. Demo cơ bản và public ảnh bằng Console

1. Đăng nhập quản trị Console. Trong **Object Browser**, tạo `demo`, upload
   `web-frontend-server/html/index.html`, tải về và mở để đối chiếu.
2. Tạo `profile-pics`, upload ảnh JPEG thật tên `avatar.jpg` ngay trong bucket.
3. Vào **Administrator → Buckets → profile-pics → Summary → Access Policy**,
   chọn **Custom**, nhập JSON sau rồi **Set**. Nếu có statement khác cần giữ,
   thêm quyền vào policy hiện có; editor lưu toàn bộ JSON, không tự trộn.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "N07PublicAvatarRead",
    "Effect": "Allow",
    "Principal": {"AWS": ["*"]},
    "Action": ["s3:GetObject"],
    "Resource": ["arn:aws:s3:::profile-pics/avatar.jpg"]
  }]
}
```

4. Mở `http://localhost:9000/profile-pics/avatar.jpg` trong cửa sổ ẩn danh: phải
   thấy ảnh không cần đăng nhập. Mở lại editor để trình bày policy đã lưu.
5. Tạo `documents`, upload PDF báo cáo, tải xuống trên Console và mở nội dung.
   Giữ bucket này private để demo quyền tài khoản và link ký bên dưới.

Dropdown Private/Public/Custom nằm sau khi tạo bucket. Public của Console này
cấp cả đọc/ghi/xóa trong bucket; Custom trên chỉ cho đọc đúng ảnh. Private gỡ
bucket policy, không thu hồi quyền đã cấp qua policy user. Cột R/W ở Object
Browser là quyền tài khoản đang đăng nhập, không phải trạng thái public.

**Giải thích với Thầy:** cùng một server nhưng avatar cho phép anonymous GET,
PDF chỉ cho người có quyền hoặc người giữ link tạm; upload không tự làm file public.

## 4. Demo tài khoản chỉ đọc và quyền theo tài nguyên

Từ tài khoản quản trị:

1. **Policies → Create Policy**: tên `n07-storage-verifier-readonly`, dán nội dung
   file [policies/storage-verifier-readonly.json](policies/storage-verifier-readonly.json), Save.
2. **Users → Create User**: tên `n07-storage-verifier`, tự đặt mật khẩu,
   chọn đúng policy trên trong Assign Policies, Save. Máy đã có user/policy thì
   mở kiểm tra, không tạo lại hoặc đổi mật khẩu mặc định.
3. Mở cửa sổ ẩn danh, đăng nhập bằng user này. Vào `documents`, tải PDF; nút
   upload/xóa phải không cho phép. Kiểm tra tự động bên dưới còn thử API thật.

Policy mẫu cho GetBucketLocation trên ba bucket, ListBucket chỉ trong documents,
GetObject chỉ cho demo/index.html, profile-pics/avatar.jpg và documents/*.
Không cấp PutObject/DeleteObject hoặc quyền admin. Policy readonly có sẵn rộng
hơn phạm vi này, nên không gán kèm consoleAdmin/readwrite/readonly cho demo trên.

Với user khác: tạo policy riêng, gán qua **Users → user → Policies → Assign Policies**.
Trong policy tài khoản không có Principal. Đổi Resource từ `documents/*` thành
`documents/bao-cao.pdf` để chỉ đọc đúng object đó; GetObject cho đọc, PutObject
cho upload/ghi đè, DeleteObject cho xóa. Giữ GetBucketLocation cho SDK; quyền
ListBucket riêng quyết định có thấy tên object khác hay không. Bỏ ListBucket thì
Object Browser có thể không duyệt được bucket, cần dùng đường dẫn/API đã biết.
Quyền từ nhiều policy/group có thể cộng thêm; kiểm trên object private vì object
đã public vẫn đọc được không cần policy tài khoản.

Demo API có kết quả đọc được, ghi/xóa/admin bị403:

```zsh
export N07_MINIO_ACCESS_KEY=n07-storage-verifier
read -rs 'N07_MINIO_SECRET_KEY?Nhập mật khẩu user kiểm thử: '
echo
export N07_MINIO_SECRET_KEY
bash scripts/verify-task5.sh --readonly
unset N07_MINIO_ACCESS_KEY N07_MINIO_SECRET_KEY
```

```powershell
$env:N07_MINIO_ACCESS_KEY = "n07-storage-verifier"
$secret = Read-Host "Nhập mật khẩu user kiểm thử" -AsSecureString
$env:N07_MINIO_SECRET_KEY = [System.Net.NetworkCredential]::new("", $secret).Password
.\scripts\verify-task5.ps1 -ReadOnly
Remove-Item Env:N07_MINIO_ACCESS_KEY, Env:N07_MINIO_SECRET_KEY
Remove-Variable secret
```

Kỳ vọng: đọc fixture đúng bytes; upload/delete/admin user listing bị403;
`SUMMARY TASK5: FAIL=0`. Phép thử dùng quản trị tạo/dọn đúng hai key UUID dưới
`documents/n07-permission-test/`; không sửa PDF/policy/user hiện có. Đây là test
có ghi tạm, không phải chỉ đọc hoàn toàn. Quyền user đã kiểm trên các API nêu trên.

**Giải thích với Thầy:** user xem tài liệu được nhưng không được làm mất/sửa dữ
liệu; quyền do Action/Resource của policy, không phải chỉ do đặt tên user readonly.

## 5. Demo link tải PDF có thời hạn

Chọn tên object PDF thật trong documents và thay vào lệnh. Từ gốc repo:

```bash
object-storage-server/.venv/bin/python object-storage-server/share_document.py 'ten-bao-cao.pdf' --minutes 1 --show-url
```

```powershell
.\object-storage-server\.venv\Scripts\python.exe .\object-storage-server\share_document.py 'ten-bao-cao.pdf' --minutes 1 --show-url
```

1. Script kiểm URL không ký bị403; link ký trả200 và bytes khớp; sửa chữ ký bị403.
2. Copy link vừa tạo vào cửa sổ ẩn danh, tải và mở PDF.
3. Sau hơn một phút, gửi GET mới bằng chính link đó trong cửa sổ ẩn danh mới:
   phải403. Hoặc chạy `curl -sS -o /dev/null -w '%{http_code}\n' '<link>'` trên Bash.
   Trên Windows dùng `curl.exe -sS -o NUL -w '%{http_code}' '<link>'`.

Script không tự chờ hết hạn; bước3 là bằng chứng expiry thực tế. Người giữ link
có quyền tải trong thời hạn; không đưa link ký vào Git hoặc ảnh chụp còn hiệu lực.
Link localhost chỉ dùng trên máy triển khai; không đổi hostname của URL sau khi ký.
Có thể dùng hai biến credential của mục4 để tạo link bằng user đọc, rồi unset.

**Giải thích với Thầy:** tài liệu vẫn private; cấp khả năng tải tạm thời qua chữ
ký thay vì công khai bucket hoặc chia sẻ mật khẩu quản trị.

## 6. Demo Logs và quyền diagnostics

1. Quản trị mở **Users → Create User**, tạo tài khoản demo với mật khẩu tự chọn,
   chỉ gán **diagnostics**. Có thể dùng tài khoản đã có đúng policy này.
2. Đăng nhập tài khoản đó ở cửa sổ ẩn danh, chọn **Logs → Start Logs**.
   Chọn **All Nodes / All Log Types** để đọc log server, dùng ô lọc khi cần.
3. Quan sát các dòng log server trả về khi có, rồi bấm **Stop Logs**.
   Trang có thể trống khi server không phát sinh log trong luồng này.
4. Đối chiếu với user readonly: không có mục Logs. User diagnostics có quyền
   chẩn đoán, không được policy này cấp đọc/ghi/xóa object hoặc quản lý user.

**Tác dụng:** phân tách người xem/chẩn đoán log với người quản trị dữ liệu.
diagnostics còn có quyền chẩn đoán khác, không phải chỉ ConsoleLog; demo hiện
tại dùng phần đọc log. Đây là Logs của MinIO, không triển khai Monitoring/Grafana
của thành viên khác. Log server không phải nhật ký đầy đủ mọi lần upload/download;
không tự nhận đã cấu hình Audit hoặc hệ thống lưu log lâu dài.

## 7. Test và file còn dùng

```bash
bash scripts/verify-task5.sh
```

```powershell
.\scripts\verify-task5.ps1
```

Task5 kiểm HTML khớp source, JPEG metadata/bytes và anonymous GET, liệt kê PDF,
private403/link ký200 đúng bytes/chữ ký sửa403. --readonly/-ReadOnly thêm phép
thử quyền mục4. Task5 không tự tạo bucket, upload báo cáo hoặc cấp policy.

| File | Công dụng |
| --- | --- |
| Dockerfile, .dockerignore | Build server + Console, không đưa runtime/secret vào image. |
| trim_console_menu.py | Bước build thu gọn sidebar, kiểm đúng checksum Console trước khi sửa. |
| requirements-client.txt | MinIO SDK cho test/link ký. |
| share_document.py | Tạo/demo link ký; cung cấp hàm kết nối dùng chung cho verifier. |
| verify_storage.py | Test HTML/avatar/PDF, được task5 gọi. |
| verify_readonly.py | Demo API đọc được, ghi/xóa/admin bị từ chối. |
| policies/storage-verifier-readonly.json | JSON được nhập vào Console cho demo user giới hạn quyền. |

Kết quả local không thay nghiệm thu EC2, thao tác upload/download UI hay nội dung
báo cáo thật. Trên máy mới phải tạo bucket/object/user/policy qua Console; dữ liệu
không tự theo Git. Override Storage cũ và script cấp quyền/tạo user bằng SDK đã
bỏ vì Compose gốc và Console hiện tại đảm nhiệm các thao tác đó.
