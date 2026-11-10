# Máy nghiệm thu MyMiniCloud

Tạo và triển khai ngày 10/11/2026 tại ap-southeast-1, theo xác nhận của người dùng.

| Thuộc tính | Giá trị |
|---|---|
| AWS account | 721274598544 |
| CLI profile | lab8-deploy |
| Instance | i-09b1a1559442a57b3 — MyMiniCloud-Final |
| OS | Ubuntu 24.04 LTS, amd64 |
| Instance type | c7i-flex.large, RAM 4 GB |
| Disk | 30 GB gp3, encrypted |
| Public IP | 13.229.212.14 |
| Security Group | sg-07b75f90eaaf94db1 |
| SSH user | ubuntu |
| Key có sẵn | D:/Users/52300119-Lab06.pem |
| Release | v1.0-final, commit 4737c47 |
| Source trên máy | /home/ubuntu/Final-CloudComputing |

Web: http://13.229.212.14/ ; API: http://13.229.212.14/api/hello ; sinh viên: http://13.229.212.14/student/ .

Các cổng quản trị/SSH/DNS chỉ cho phép IP 118.69.36.3/32. Cổng 80 public.
Nếu IP người dùng đổi, cần cập nhật rule giới hạn IP trước khi truy cập quản trị.
MariaDB 3306 không mở ra Internet.

```powershell
ssh -i 'D:/Users/52300119-Lab06.pem' ubuntu@13.229.212.14
```

Mật khẩu quản trị EC2 được tạo ngẫu nhiên, không dùng mật khẩu mặc định Local.
File bí mật trên EC2: `/home/ubuntu/Final-CloudComputing/.env` (mode 600).
Bản sao chỉ trên máy người dùng: `C:/Users/User/.ssh/myminicloud-final.env`.
Không upload hai file này lên Git/Overleaf hoặc đưa vào ảnh/video.

Tài khoản không có quyền ec2:ImportKeyPair nên dùng key pair đã có. AWS chặn
t3.medium do điều kiện Free Tier; người dùng đã duyệt đổi sang c7i-flex.large.

Repository là private: source được chuyển bằng git archive của tag phát hành,
không lưu credential GitHub trên EC2. Web/App được pull từ Docker Hub; image
MinIO build source đã nghiệm thu ở Local được chuyển bằng docker save/load.

Avatar vẫn là ảnh tạm. PDF trong documents/bao-cao-nghiem-thu-local.pdf là báo
cáo nghiệm thu Local thực tế, chưa phải bản nộp cuối. Cần thay dữ liệu trước khi nộp.

Máy đang Running để nghiệm thu/demo. Sau khi dùng xong, Stop máy để tránh phí
compute; đĩa EBS vẫn có thể phát sinh phí khi máy dừng. Không tự dừng/terminate
ba máy Lab 6/7/8 khác trong cùng tài khoản.
