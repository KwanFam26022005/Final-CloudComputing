# 🪣 5. Object Storage Server (`object-storage-server`)

> **Thành viên phụ trách:** Thành viên 3 (Security, Storage & DNS Lead)  
> **Container Name:** `object-storage-server` (API Port `9000:9000`, Console Port `9001:9001`)  
> **Network Aliases (`cloud-net`):** `minio`, `storage`, `minio.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ lưu trữ đối tượng phi cấu trúc chuẩn S3 (tương tự **Amazon S3**) sử dụng **MinIO**. Dữ liệu được lưu bền vững qua volume `./object-storage-server/data:/data`.

## 2. Thông Tin Đăng Nhập
- **MinIO Console UI:** `http://localhost:9001`
- **S3 API Endpoint:** `http://localhost:9000`
- **Username / Password:** `minioadmin` / `minioadmin`

## 3. Nhiệm Vụ Thực Hiện & Demo
1. **Phần Cơ bản (#5):**
   - Đăng nhập `http://localhost:9001`.
   - Tạo bucket tên **`demo`**.
   - Upload file `web-frontend-server/html/index.html` vào bucket `demo`.
2. **Phần Mở rộng (#5 - 0.5 điểm):**
   - Tạo bucket tên **`profile-pics`**; cấp quyền public đọc đúng object `avatar.jpg`
     bằng công cụ ở mục 5, không cần công khai cả bucket.
   - Upload ảnh đại diện **`avatar.jpg`** và mở đường dẫn public trực tiếp trên trình duyệt: `http://localhost:9000/profile-pics/avatar.jpg`.
   - Tạo thêm bucket tên **`documents`** và upload file **PDF báo cáo** của nhóm.

## 4. Khởi chạy từ Compose gốc (local và máy triển khai mới)

Compose gốc đã khai báo `build: ./object-storage-server` và image local cố định
`myminicloud-minio:RELEASE.2025-10-15T17-29-55Z`, với `pull_policy: build`.
`docker compose up -d` tự build từ Dockerfile, không cố pull `minio/minio:latest`.
Không cần Docker login hoặc file override để chạy Storage.

```bash
# Chạy cả cụm khi các module nhóm đã sẵn sàng:
docker compose up -d
# Hoặc chỉ kiểm tra Storage:
docker compose up -d --no-deps object-storage-server
docker compose ps object-storage-server
```

Lần đầu cần Internet để tải base image, source MinIO và Go modules; build có thể
mất vài phút. Các lần sau dùng build cache. Có thể chủ động build trước bằng
`docker compose build object-storage-server`. Base image được ghim multi-platform
digest; Dockerfile không ép ARM64, có thể build theo kiến trúc máy đích.
Đã có healthcheck trong Dockerfile. `object-storage-server/data:/data` giữ nguyên
để không mất bucket/object/policy/tài khoản hiện có. Không xóa data để sửa lỗi pull.
`.dockerignore` loại runtime data và credential khỏi build context.

`compose.source.yml` chỉ còn là tương thích với lệnh cũ, không phải điều kiện
khởi chạy. Khi cập nhật code, vẫn phải nhận đủ Dockerfile, .dockerignore và Compose
trong cùng PR. Nguồn: [MinIO release chính thức](https://github.com/minio/minio/releases/tag/RELEASE.2025-10-15T17-29-55Z).

### TV4 triển khai EC2

Clone nhánh tích hợp sau khi leader merge PR. Chuẩn bị `.env` trên EC2 (không commit)
và cổng/Security Group theo phân công. Chạy Compose từ gốc repo; build MinIO sẽ diễn
ra ngay trên máy EC2, không cần image đã tồn tại trên Mac của thành viên 3.
Bucket/object/tài khoản runtime phải khởi tạo lại hoặc chuyển dữ liệu có chủ đích;
không tự đi theo Git. Tiện ích Python hiện dùng API `localhost:9000` để chạy ngay
trên host local/EC2; link ký đó không dùng cho trình duyệt máy khác nếu chưa thống
nhất public endpoint với Backend/Gateway. Không sửa hostname của link sau khi ký.
Các chức năng runtime trên EC2 phải được kiểm thử lại, không dùng kết quả Mac thay thế.

## 5. Cấp quyền đọc công khai avatar bằng SDK chính thức

Chuẩn bị sau khi đã upload ảnh JPEG thật tên `profile-pics/avatar.jpg`:

```bash
python3 -m venv object-storage-server/.venv
object-storage-server/.venv/bin/python -m pip install -r object-storage-server/requirements-client.txt
object-storage-server/.venv/bin/python object-storage-server/set_avatar_public.py --apply
```

Script dùng MinIO Python SDK, đọc credential từ cấu hình Compose local mà không
in hoặc lưu credential ra file. Nó kiểm tra ảnh trước khi thêm policy cho phép
anonymous `s3:GetObject` đúng object `profile-pics/avatar.jpg`, giữ các statement
policy khác và không đổi bucket khác. Sau khi apply, script kiểm tra HTTP GET
không đăng nhập: 200, `image/jpeg`, nội dung bằng object đọc có xác thực.
Policy đã được ghi trước bước HTTP kiểm tra; nếu bước sau lỗi, cần kiểm tra lại
policy hiện có thay vì giả định chưa có thay đổi.

Bỏ `--apply` để xem grant đề xuất mà không đổi policy. `.venv/` được Git ignore.
Việc kiểm tra SDK/ảnh/public URL chỉ được xác nhận đạt khi lệnh chạy thành công.
Nguồn API: [ví dụ set_bucket_policy của SDK chính thức](https://github.com/minio/minio-py/blob/master/examples/set_bucket_policy.py).

## 6. Cải tiến tự chọn: tải PDF riêng tư bằng link có thời hạn

Đây là tiện ích phát triển từ Storage GV-MR05, không phải mục điểm mới của đề.
Không sửa App, Compose, object hoặc bucket policy. Cần Docker Desktop đang chạy,
MinIO local đã khởi động và môi trường Python ở mục 5 đã cài dependencies.

```bash
object-storage-server/.venv/bin/python object-storage-server/share_document.py 'N07_CLoud-Quy-Uoc-Trien-Khai-Nhom-v1.2.pdf' --minutes 1 --show-url
```

Thay tên PDF bằng object thực tế nếu khác. Script yêu cầu unsigned GET=403,
signed GET=200 và bytes khớp, link sửa chữ ký=403; thất bại trả exit code 1.
Mặc định link có hiệu lực 5 phút; demo cho phép 1–60 phút. `--show-url` chỉ in link
khi muốn thử trình duyệt. Người có link có thể tải tệp trong thời hạn: không ghi
link vào nhật ký, ảnh minh chứng hoặc Git. Script không lưu link/credential.

Kiểm tra hết hạn thực tế riêng: mở link vừa tạo trong cửa sổ ẩn danh, sau hơn
một phút gửi GET mới bằng link cũ (tránh dùng bản đã cache); mong đợi 403.
Script chưa tự nghiệm thu thời điểm hết hạn. URL localhost chỉ dùng trên máy này;
chưa tích hợp App/EC2. Công cụ mặc định dùng credential Compose local cho demo;
mục 8 hướng dẫn chuyển sang tài khoản chỉ đọc bằng biến môi trường.

## 7. Kiểm tra Storage bằng một lệnh (chỉ đọc)

```bash
object-storage-server/.venv/bin/python object-storage-server/verify_storage.py --pdf 'N07_CLoud-Quy-Uoc-Trien-Khai-Nhom-v1.2.pdf'
```

Công cụ đối chiếu demo/index.html với source Web local (không sửa Web), kiểm tra
avatar có JPEG bytes/metadata, anonymous GET200 và nội dung khớp; gọi lại tiện ích
share_document.py không in URL để kiểm tra PDF thật, unsigned403, signed200/bytes
khớp và chữ ký sửa bị từ chối403. Tên PDF được truyền rõ qua --pdf.
Kết quả cuối RESULT: PASS; 0 failed group(s) trả exit0; lỗi trả exit1.
Nếu source Web đổi sau lần upload, kiểm tra demo sẽ báo khác phiên bản để đối chiếu.
Không thay object/policy, không lưu credential/link. Không kiểm tra tự động thời gian
hết hạn, UI Console, nội dung báo cáo thật hoặc EC2; kết quả trước đây không thay
cho lần chạy sau khi cấu hình đổi. Căn cứ GV-07 và GV-MR05; tự động hóa là cải tiến
tự chọn, không phải mục điểm bổ sung.

### Kiểm tra tất cả PDF trong documents

```bash
object-storage-server/.venv/bin/python object-storage-server/verify_storage.py --all-pdfs
```

Chọn một trong --pdf hoặc --all-pdfs. Chế độ tất cả liệt kê object hiện tại có đuôi
.pdf (không phân biệt hoa/thường), gồm đường dẫn con, và kiểm tra lần lượt từng
file bằng cùng phép thử PDF/private/signed/tampered. File lỗi không dừng việc kiểm
tra file kế tiếp; kết quả PDF SUMMARY chỉ rõ số file đạt/tổng và RESULT thất bại
nếu có bất kỳ nhóm lỗi. Bucket không có PDF hoặc không liệt kê được cũng báo lỗi,
không báo đạt khi chưa kiểm tra file nào. Không kiểm tra version cũ hoặc các file
không có đuôi .pdf. Danh sách là tại thời điểm liệt kê, không khóa bucket khi chạy;
nên chạy lúc không có thao tác ghi/xóa đồng thời. Demo và avatar vẫn được kiểm tra
một lần. Link được tạo riêng từng PDF, không in/lưu và không chờ hết hạn.

## 8. Cải tiến tự chọn: tài khoản kiểm thử quyền đọc tối thiểu

Policy policies/storage-verifier-readonly.json chỉ cho GetBucketLocation trên3bucket,
ListBucket trên documents và GetObject cho demo/index.html, profile-pics/avatar.jpg,
mọi object trong documents. Không cấp quyền ghi/xóa/admin. Đây là phát triển từ GV-MR05, không phải
mục điểm riêng, chưa phải tích hợp userKeycloak/IAMAWS/App.

```bash
# Xem chính sách, không gọi API hoặc thay đổi server:
object-storage-server/.venv/bin/python object-storage-server/create_readonly_user.py
# Tạo riêng tài khoản/policy mới, nhập secret ẩn hai lần:
object-storage-server/.venv/bin/python object-storage-server/create_readonly_user.py --apply
```

Tên user n07-storage-verifier và policy n07-storage-verifier-readonly. Script dùng
credential quản trị Compose riêng cho việc tạo user. Từ chối ghi đè user/policy đã
có; tạo policy/user/attach không transactional: nếu lỗi, giữ nguyên phần đã tạo để
kiểm tra, không tự xóa hoặc chạy đi chạy lại. Không đổi bucket policy/tài khoản cũ.
Secret tự chọn ít nhất16ký tự, không in/lưu; người dùng phải giữ bằng cách an toàn.
Nếu mất secret, cần quy trình đổi có chủ đích, không xóa dữ liệu hoặc tài khoản khác.

Công cụ share_document.py và verify_storage.py hỗ trợ N07_MINIO_ACCESS_KEY và
N07_MINIO_SECRET_KEY trong môi trường (cả hai phải có và khôngrỗng). Khi có biến sẽ
chỉ dùng tài khoản này, không fallback quản trị nếu thông tin sai. Không cần Docker
Compose để lấy credential khi đã cung cấp cả hai. Khi không đặt biến, giữ cách chạy
lab cũ bằng credential Compose; đây là tương thích cũ, không phải ép dùng quyền tối
thiểu mặc định. Không ghi secret vào lệnh/shellhistory/.env chung/Git.

Ví dụ zsh sau khi tạo tài khoản thành công:

```zsh
export N07_MINIO_ACCESS_KEY=n07-storage-verifier
read -rs 'N07_MINIO_SECRET_KEY?Nhập secret tài khoản kiểm thử: '
echo
export N07_MINIO_SECRET_KEY
object-storage-server/.venv/bin/python object-storage-server/verify_storage.py --all-pdfs
unset N07_MINIO_ACCESS_KEY N07_MINIO_SECRET_KEY
```

Chưa kết luận quyền thực tế chỉ từ policy: cần kiểm tra đọc/list/link ký thành công
và các thao tác ghi/xóa/admin bị từ chối bằng đối tượng thử an toàn ở bước tiếp.
Script set_avatar_public.py vẫn là tác vụ quản trị riêng, không dùng tài khoản đọc.
Nguồn SDKAdmin: https://github.com/minio/minio-py/blob/7.2.20/minio/minioadmin.py .

### Kiểm thử quyền bị từ chối bằng tệp tạm

Sau khi tài khoản đọc chạy verify_storage.py đạt, đặt hai biến môi trường như trên,
sau đó chạy verify_readonly.py thay cho verify_storage.py, echo $? ngay sau và unset
credential. Không cần đổi user/policy. Công cụ yêu cầu đúng user n07-storage-verifier;
không có credential sẽ trả exit1 trước mọi API call.

```zsh
object-storage-server/.venv/bin/python object-storage-server/verify_readonly.py
echo "Exit code: $?"
```

Công cụ dùng admin Compose để tạo một fixture văn bản không bí mật dưới prefix
n07-permission-test/<UUID> trong documents. Dùng verifier để đọc fixture, thử upload
key khác, xóa fixture và gọi admin user_list; mong đợi đọc được, ba phép thử bị từ
chối403. So sánh policy documents trước/sau. Trong finally dùng root xóa đúng hai
key UUID, kể cả khi ghi bằng verifier bất ngờ thành công; không xóa PDF hiện hữu.
Nếu cleanup lỗi do mạng/server, kiểm tra đúng prefix được in, không xóa toàn bucket.
Đây là phép thử có ghi tạm, không phải script read-only hoàn toàn. RESULTPASS/exit0
chỉ xác nhận cácAPI cụ thể này, không chứng minh mọi khả năng bảo mật/EC2 hoặc mọi
quyềnadmin đều đã được thử. Secret không in/lưu; quyền quản trị chỉ dùng chuẩn bị/dọn
fixture, kiểmpolicy; các thao tác thử quyền dùng verifier riêng.

Kết quả local ngày28/10/2026: tài khoản n07-storage-verifier chạy bộ Storage
2/2PDF PASS/exit0; phép thử quyền đọc fixture thành công, upload/delete bị
AccessDenied403, admin user_list403, policy documents giữ nguyên và cleanup hoàn
tất, RESULTPASS/exit0. Chỉ xác nhận cácAPI đã thử, chưa nghiệm thu EC2 hoặc tích hợp
Keycloak. Khuyến nghị dùng credential verifier qua biến môi trường cho các công cụ
đọc; tác vụ quản trị vẫn dùng tài khoản quản trị riêng. Account/policy nằm trong
dữ liệu MinIO local; trên máy triển khai mới cần tạo lại hoặc chuyển dữ liệu có
chủ đích, không tự có khi chỉ clone repo. Không chạy --apply ghi đè tài khoản cũ.

Các file PDF được nhắc trong lệnh là dữ liệu demo local, không nằm trong repo;
hãy upload PDF của mình rồi truyền đúng tên object. Mã GV-07/GV-MR05 là mã truy
vết local cho kiểm thử Storage cơ bản/phần mở rộng MinIO trong đề Thầy, không
yêu cầu tải tài liệu local của người khác. Đây là bộ tiện ích local, chưa là
API hoặc giao diện quản lý tệp trên website.

## Script task5

Sau khi chuẩn bị venv/SDK ở trên, từ gốc repo chạy `bash scripts/verify-task5.sh` hoặc
`./scripts/verify-task5.ps1`. Script dùng các verify đã chuyển vào `scripts/`.
Nội dung: HTML khớp source, JPEG public, PDF private, link ký đúng/sai chữ ký.
`--readonly` (PowerShell: `-ReadOnly`) chạy kiểm quyền bằng fixture UUID khi có credential verifier.
Mặc định giữ nguyên bucket/object/policy; thao tác UI và thời điểm hết hạn thực tế kiểm riêng.
