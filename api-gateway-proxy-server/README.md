# 🔀 9. API Gateway / Reverse Proxy Server (`api-gateway-proxy-server`)

> **Thành viên phụ trách:** Thành viên 1 (Gateway & Web Lead)  
> **Container Name:** `api-gateway-proxy-server` (Port `80:80`)  
> **Network Aliases (`cloud-net`):** `proxy`, `gateway`

---

## 1. Mục Đích & Vai Trò
Đóng vai trò là cổng vào duy nhất (Single Entry Point / Reverse Proxy & Load Balancer) ở cổng `80`, định tuyến lưu lượng truy cập từ người dùng tới đúng microservice bên trong mạng `cloud-net`.

## 2. Cấu Hình Định Tuyến (`nginx.conf`)
- **`location /`**: Chuyển tiếp tới cụm `upstream web_backend` gồm `web-frontend-server:80` và `web-frontend-server2:80` theo thuật toán **Round Robin** (**Mở rộng #10**).
- **`location /api/`**: Strip tiền tố `/api/` và chuyển tiếp tới `http://application-backend-server:8081/`.
- **`location /student/`**: Định tuyến thẳng tới `http://application-backend-server:8081/student` (**Mở rộng #9**).
- **`location /auth/`**: Chuyển tiếp tới `http://authentication-identity-server:8080/` (Keycloak).

## 3. Lệnh Kiểm Thử Nhanh
```bash
# Kiểm tra 3 route cơ bản
curl -I http://localhost/
curl -s http://localhost/api/hello
curl -I http://localhost/auth/

# Kiểm tra Mở rộng #9 (Route /student/)
curl -s http://localhost/student/

# Kiểm tra Mở rộng #10 (Load Balancing Round Robin luân phiên giữa 2 Web Server)
curl -I http://localhost/
curl -I http://localhost/
```
