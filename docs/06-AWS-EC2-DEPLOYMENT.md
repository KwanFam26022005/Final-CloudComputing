# 06. Hướng Dẫn Push Docker Hub & Triển Khai Trên AWS EC2 (Ubuntu)

Theo yêu cầu bắt buộc của đề bài:
1. **Push ít nhất 1 custom image** lên **Docker Hub**.
2. **Deploy toàn bộ hệ thống trên AWS EC2 (Ubuntu)** và truy cập được qua **Public IP**.

Tài liệu này hướng dẫn từng bước thực hiện chuẩn xác để nhóm đạt điểm tuyệt đối.

---

## Phần 1: Đẩy Custom Images Lên Docker Hub

Hệ thống có 2 custom image được build từ `Dockerfile` riêng của nhóm là `web-frontend-server` và `application-backend-server`.

```bash
# Bước 1: Đăng nhập vào Docker Hub trên terminal
docker login

# Bước 2: Build image với tên tài khoản Docker Hub của bạn (thay <dockerhub_user> bằng username thật)
docker build -t <dockerhub_user>/myminicloud-web:latest ./web-frontend-server
docker build -t <dockerhub_user>/myminicloud-app:latest ./application-backend-server

# Bước 3: Push cả 2 image lên Docker Hub
docker push <dockerhub_user>/myminicloud-web:latest
docker push <dockerhub_user>/myminicloud-app:latest
```
> 📸 **Lưu ý Báo cáo:** Chụp ảnh màn hình trang Docker Hub Repository hiển thị 2 image `<dockerhub_user>/myminicloud-web` và `<dockerhub_user>/myminicloud-app` để đưa vào **Phụ lục** báo cáo.

---

## Phần 2: Khởi Tạo Máy Chủ Ảo AWS EC2 (Ubuntu)

### 1. Cấu hình khuyến nghị khi tạo EC2 Instance
- **AMI (Hệ điều hành):** `Ubuntu Server 22.04 LTS` hoặc `Ubuntu Server 24.04 LTS` (64-bit x86).
- **Instance Type (Cấu hình phần cứng):**
  - **Khuyến nghị:** **`t3.medium`** hoặc **`t2.medium`** (2 vCPU, **4 GB RAM**).
  - *Lưu ý:* Nếu dùng `t2.micro` / `t3.micro` (1 GB RAM), do chạy đồng thời 10+ containers (đặc biệt là Keycloak chạy JVM và MariaDB), bạn **bắt buộc phải tạo thêm 4 GB Swap RAM** theo lệnh ở Mục 3 bên dưới để không bị treo máy (`Out of Memory`).
- **Storage (Ổ cứng EBS):** Tối thiểu **`20 GB`** (gp3/gp2).

### 2. Cấu hình Security Group (Inbound Rules)
Mở các cổng sau trong **Security Group** của EC2 để có thể truy cập và kiểm thử từ trình duyệt qua Public IP:

| Type | Protocol | Port Range | Source | Mục đích |
| :--- | :---: | :---: | :---: | :--- |
| **SSH** | TCP | `22` | `0.0.0.0/0` *(hoặc My IP)* | Quản trị máy chủ từ xa qua SSH |
| **HTTP** | TCP | `80` | `0.0.0.0/0` | Truy cập **API Gateway / Reverse Proxy** (`/`, `/api/`, `/student/`, `/auth/`) |
| **Custom TCP** | TCP | `3000` | `0.0.0.0/0` | Truy cập **Grafana Dashboard** |
| **Custom TCP** | TCP | `8080` | `0.0.0.0/0` | Truy cập trực tiếp **Web Server 1** |
| **Custom TCP** | TCP | `8081` | `0.0.0.0/0` | Truy cập **Keycloak Admin Console** |
| **Custom TCP** | TCP | `8082` | `0.0.0.0/0` | Truy cập trực tiếp **Web Server 2 (Replica)** |
| **Custom TCP** | TCP | `8085` | `0.0.0.0/0` | Truy cập trực tiếp **Application Backend API** |
| **Custom TCP** | TCP | `9000 - 9001` | `0.0.0.0/0` | Truy cập **MinIO S3 API (`9000`) & Console (`9001`)** |
| **Custom TCP** | TCP | `9090` | `0.0.0.0/0` | Truy cập **Prometheus UI** |
| **Custom TCP** | TCP | `9100` | `0.0.0.0/0` | Truy cập **Node Exporter Metrics** *(tùy chọn)* |

---

## Phần 3: Cài Đặt Docker & Triển Khai Dự Án Trên EC2

### Bước 1: Kết nối SSH vào EC2
```bash
ssh -i "path/to/your-key.pem" ubuntu@<EC2_PUBLIC_IP>
```

### Bước 2: Tạo Swap 4GB (Rất quan trọng để tránh tràn RAM khi chạy Keycloak + MariaDB)
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

### Bước 3: Cài đặt Docker Engine & Docker Compose v2 trên Ubuntu
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git dnsutils
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Cho phép user ubuntu chạy docker không cần sudo
sudo usermod -aG docker ubuntu
newgrp docker
```

### Bước 4: Clone Repository & Khởi chạy MyMiniCloud
```bash
git clone https://github.com/KwanFam26022005/Final-CloudComputing.git
cd Final-CloudComputing

# Tạo file .env và cập nhật KC_HOSTNAME thành Public IP của EC2 (hoặc giữ nguyên vì KC_HOSTNAME_STRICT=false)
cp .env.example .env

# Build và chạy toàn bộ 10+ containers
docker compose up -d --build

# Kiểm tra trạng thái
docker compose ps
```

### Bước 5: Chạy Script Kiểm Thử Tự Động Trên EC2
```bash
chmod +x scripts/*.sh
./scripts/verify-base.sh
./scripts/verify-extended.sh
```

### Bước 6: Kiểm tra từ trình duyệt máy tính cá nhân qua `<EC2_PUBLIC_IP>`
- `http://<EC2_PUBLIC_IP>/` (API Gateway & Load Balancer)
- `http://<EC2_PUBLIC_IP>/blog/` (Trang Blog cá nhân 3 bài viết)
- `http://<EC2_PUBLIC_IP>/api/hello` & `http://<EC2_PUBLIC_IP>/student/` (Flask API)
- `http://<EC2_PUBLIC_IP>:8081` (Keycloak Admin Console)
- `http://<EC2_PUBLIC_IP>:9001` (MinIO Console)
- `http://<EC2_PUBLIC_IP>:9090/targets` (Prometheus Targets UP)
- `http://<EC2_PUBLIC_IP>:3000` (Grafana Dashboard)

> 📸 **Lưu ý Báo cáo:** Khi chụp ảnh màn hình trên AWS EC2, hãy chụp **toàn bộ cửa sổ trình duyệt nhìn thấy rõ thanh địa chỉ chứa `<EC2_PUBLIC_IP>`** để giảng viên xác nhận hệ thống đã chạy thật trên Cloud!
