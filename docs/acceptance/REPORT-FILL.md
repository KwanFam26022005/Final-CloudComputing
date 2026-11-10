# Nội dung cập nhật báo cáo sau triển khai EC2

Ngày nghiệm thu: 10/11/2026. Bản phát hành: `v1.0-final`, commit `4737c47`.
Không ghi đã hoàn tất dữ liệu cá nhân, video hoặc mọi thao tác UI chỉ dựa trên log tự động.

## Bảng trạng thái tổng quát

| Phần | Kết quả |
|---|---|
| Local | 10/10 cơ bản, 10/10 mở rộng về chức năng; avatar/PDF còn tạm và một số ảnh có lưu ý trong RESULTS.md |
| EC2 | 11 container Up; verify-base PASS=26 FAIL=0; verify-extended PASS=17 FAIL=0; Task4/5/6 FAIL=0 |
| Docker Hub | Hai repository public, tag v1.0, đã pull thành công trên EC2 |
| Dữ liệu cuối | Chưa có avatar cá nhân và PDF nộp cuối; video còn chờ |

## Mục 4.3 Triển khai và kiểm thử AWS EC2

Hệ thống được triển khai trên Ubuntu 24.04 LTS amd64 tại region ap-southeast-1.
Máy MyMiniCloud-Final (i-09b1a1559442a57b3) dùng loại c7i-flex.large, RAM 4 GB,
ổ đĩa EBS gp3 30 GB có mã hóa. Public IP tại thời điểm kiểm thử là 13.229.212.14.
Security Group sg-07b75f90eaaf94db1 mở HTTP 80 phục vụ demo; SSH và các cổng
quản trị, DNS chỉ cho phép IP máy nghiệm thu. MariaDB 3306 không mở ra Internet.

Source được đóng gói từ tag v1.0-final và chuyển qua SSH do repository là private.
Web và App được kéo từ Docker Hub với tag v1.0. MinIO sử dụng image build từ
source của nhóm đã kiểm tra ở Local, chuyển bằng docker save/load. Không lưu
credential GitHub trên máy chủ. Mật khẩu quản trị EC2 được tạo riêng và giữ
trong file .env quyền 600, không đưa vào Git hoặc báo cáo.

Sau khởi động, đủ 11 container ở trạng thái Up, MinIO healthy. Bộ verify-base
trả PASS=26 FAIL=0 và verify-extended trả PASS=17 FAIL=0, đều exit 0. Bộ kiểm
thử Task4 (OIDC), Task5 (Storage) và Task6 (DNS/mạng) đều FAIL=0. Từ Windows
qua Public IP, token/UserInfo của hai user và API secure trực tiếp/qua Gateway
được kiểm tra lại; mỗi API secure đạt 5/5 phép thử.

| URL từ máy nghiệm thu | Kết quả |
|---|---|
| http://13.229.212.14/ | HTTP 200, Home |
| http://13.229.212.14/blog/ | HTTP 200 |
| http://13.229.212.14/api/hello | HTTP 200, JSON đúng |
| http://13.229.212.14/api/student | HTTP 200, 5 sinh viên |
| http://13.229.212.14/student/ | HTTP 200, 5 sinh viên |
| http://13.229.212.14/api/students-db | HTTP 200, dữ liệu MariaDB |
| http://13.229.212.14/api/secure | Token hợp lệ 200; thiếu/sai token và sửa chữ ký 401 |
| http://13.229.212.14:9000/profile-pics/avatar.jpg | HTTP 200, JPEG tạm public |
| http://13.229.212.14:9090/targets | Trình duyệt hiển thị node 1/1, web 2/2, prometheus 1/1 UP |

Sáu request liên tiếp tới Gateway cho X-Served-By luân phiên Primary/Replica.
Ảnh thực tế: ec2-dich-vu.png, ec2-prometheus.png, ec2-student.png.
Thông số máy có trong logs/ec2-instance.json; ảnh AWS Console/Security Group còn cần bổ sung.

## Mục 4.4 Tổng hợp log

- Local verify-base: PASS=26 FAIL=0.
- Local verify-extended: PASS=17 FAIL=0.
- EC2 verify-base: PASS=26 FAIL=0.
- EC2 verify-extended: PASS=17 FAIL=0.
- EC2 Task4/5/6: FAIL=0.
- EC2 từ Windows: OIDC, App secure, Gateway secure đều exit 0.

26 và 17 là số phép kiểm tra nhỏ của script, không phải số yêu cầu hoặc số ảnh.
Các log tương ứng đặt trong docs/acceptance/logs/.

## Chương 5 Sự cố và hạn chế bổ sung

- Tài khoản AWS chặn t3.medium theo điều kiện Free Tier; nhóm chuyển sang
  c7i-flex.large sau xác nhận cấu hình. Đủ điều kiện Free Tier không có nghĩa mọi chi phí bằng 0.
- IAM user không có ec2:ImportKeyPair; dùng key pair có sẵn để SSH vào máy riêng.
- Edge tự động chặn HTTP, Chrome truy cập được. Ảnh ec2-browser-error.png chỉ là
  ghi nhận lỗi trình duyệt, không dùng làm minh chứng PASS.
- Avatar EC2 vẫn tạm. PDF EC2 là báo cáo nghiệm thu Local thực tế, chưa phải bản nộp cuối.
- Chưa kiểm tra recreate/reboot toàn cụm EC2; issuer/audience/expiry JWT vẫn là
  hạn chế của backend. Readonly và chờ hết hạn link ký MinIO chưa được chạy trong lần này.
- Ảnh AWS Console, thao tác UI quản trị EC2 và video cần bổ sung trước khi nộp.

## Phụ lục liên kết phát hành

- GitHub tag: https://github.com/KwanFam26022005/Final-CloudComputing/tree/v1.0-final
- Web: https://hub.docker.com/r/kwan2602/myminicloud-web/tags (v1.0).
- App: https://hub.docker.com/r/kwan2602/myminicloud-app/tags (v1.0).
- Ảnh Docker Hub: phu-luc-dockerhub.png và phu-luc-dockerhub-app.png.
- Video demo: CHỜ người dùng quay/cung cấp liên kết.

Chưa cập nhật trực tiếp Overleaf hoặc biên dịch lại PDF từ các thay đổi trong file này.
