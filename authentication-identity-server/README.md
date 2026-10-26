# 🔐 4. Authentication & Identity Server (`authentication-identity-server`)

> **Thành viên phụ trách:** Thành viên 3 (Security, Storage & DNS Lead)  
> **Container Name:** `authentication-identity-server` (Port `8081:8080`)  
> **Network Aliases (`cloud-net`):** `keycloak`, `auth`, `keycloak.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng hệ thống Quản lý Định danh và Truy cập tập trung (Identity Provider - IdP / Single Sign-On tương tự AWS IAM Identity Center / Amazon Cognito) sử dụng **Keycloak** theo giao thức **OpenID Connect (OIDC)**.

## 2. Tự Động Khởi Tạo Realm Mở Rộng (`import/realm-export.json`)
Container Keycloak được cấu hình chạy với cờ `start-dev --import-realm`, tự động nạp file `import/realm-export.json` khi khởi động:
- **Realm:** `realm_sv001` *(Thành viên 3 có thể đổi tên theo MSSV thật của mình)*
- **Client:** `flask-app` (`Access Type: public`, `Direct Access Grants: Enabled`)
- **2 Users tạo sẵn:**
  - `sv01` (Password: `sv01pass`)
  - `sv02` (Password: `sv02pass`)
- **Tài khoản Admin mặc định:** `admin` / `admin` tại `http://localhost:8081`.

## 3. Lệnh Kiểm Thử Lấy Token & Gọi `/secure` (Mở rộng #4)
```bash
# 1. Lấy Access Token từ Keycloak cho user sv01
curl -s -X POST "http://localhost:8081/realms/realm_sv001/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=flask-app" \
  -d "username=sv01" \
  -d "password=sv01pass" \
  -d "grant_type=password"

# 2. Dùng Access Token gọi vào API bảo mật /api/secure
curl -H "Authorization: Bearer <ACCESS_TOKEN>" http://localhost/api/secure
```
