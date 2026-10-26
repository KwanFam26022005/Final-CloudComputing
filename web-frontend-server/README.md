# 🌐 1. Web Frontend Server (`web-frontend-server`)

> **Thành viên phụ trách:** Thành viên 1 (Gateway & Web Lead)  
> **Container Name:** `web-frontend-server` (Port `8080:80`) & `web-frontend-server2` (Port `8082:80`)  
> **Network Aliases (`cloud-net`):** `web`, `web-server`, `web-frontend-server1`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ lưu trữ website tĩnh (Static Web Hosting tương tự Amazon S3 Static Website / Nginx Web Server), phục vụ trang chủ `/` và chuyên mục `/blog/` thông qua cơ chế `alias` của Nginx.

## 2. Cấu Trúc Thư Mục
- `Dockerfile`: Đóng gói image Nginx tùy chỉnh, nhúng biến `SERVER_NODE_NAME` để phân biệt Server 1 và Server 2 khi kiểm thử cân bằng tải.
- `conf.default`: Cấu hình Nginx server block:
  - Phục vụ `/` từ `/usr/share/nginx/html`.
  - Phục vụ `/blog/` qua `alias /usr/share/nginx/html/blog/;`.
  - Cung cấp endpoint `/metrics` trả về định dạng Prometheus để hỗ trợ **Mở rộng #7** đạt trạng thái `UP`.
- `html/index.html`: Trang chủ hiển thị danh sách bài viết blog.
- `html/blog/index.html`, `blog1.html`, `blog2.html`, `blog3.html`: Ba bài viết blog cá nhân kèm hình ảnh minh họa và liên kết quay về.

## 3. Nhiệm Vụ Của Thành Viên 1
1. **Phần Cơ bản:** Đảm bảo `http://localhost:8080/` và `http://localhost:8080/blog/` trả về `200 OK`.
2. **Phần Mở rộng #1 (0.5 điểm):** Tùy chỉnh nội dung cá nhân hóa cho 3 bài viết `blog1.html`, `blog2.html`, `blog3.html` trong `html/blog/`.
3. **Push Docker Hub:**
   ```bash
   docker build -t <dockerhub_user>/myminicloud-web:latest ./web-frontend-server
   docker push <dockerhub_user>/myminicloud-web:latest
   ```

## 4. Lệnh Kiểm Thử Nhanh
```bash
curl -I http://localhost:8080/
curl -I http://localhost:8080/blog/
curl -I http://localhost:8080/blog/blog1.html
curl -s http://localhost:8080/metrics
```
