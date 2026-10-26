# ⚙️ 2. Application Backend Server (`application-backend-server`)

> **Thành viên phụ trách:** Thành viên 2 (Backend & Data Lead)  
> **Container Name:** `application-backend-server` (Port `8085:8081`)  
> **Network Aliases (`cloud-net`):** `app`, `app-server`, `app-backend`, `app-backend.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng tầng xử lý nghiệp vụ Microservice / REST API viết bằng Python Flask, kết nối trực tiếp với MariaDB (`relational-database-server`) và xác thực người dùng qua Keycloak OIDC (`authentication-identity-server`).

## 2. Danh Sách API Endpoints
| Endpoint (Trực tiếp `:8085`) | Qua API Gateway (`:80`) | Hạng mục | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET /hello` | `GET /api/hello` | Cơ bản #2 | Trả về JSON `{"message": "Hello from App Server!"}`. |
| `GET /secure` | `GET /api/secure` | Cơ bản #2 & Mở rộng #4 | Kiểm tra chữ ký RS256 của JWT Bearer Token từ Keycloak và trả về `preferred_username`. |
| `GET /student` | `GET /api/student` & `GET /student/` | Mở rộng #2 & #9 | Đọc danh sách 5 sinh viên từ file tĩnh `students.json`. |
| `GET /students-db` | `GET /api/students-db` | Mở rộng #3 | Truy vấn trực tiếp bảng `students` trong CSDL `studentdb` trên MariaDB. |

## 3. Nhiệm Vụ Của Thành Viên 2
1. Cập nhật thông tin thật của các thành viên trong `students.json` (Mở rộng #2).
2. Phối hợp với `relational-database-server/init/002_studentdb.sql` để kiểm thử kết nối `/students-db` (Mở rộng #3).
3. Build và push image lên Docker Hub:
   ```bash
   docker build -t <dockerhub_user>/myminicloud-app:latest ./application-backend-server
   docker push <dockerhub_user>/myminicloud-app:latest
   ```

## 4. Lệnh Kiểm Thử Nhanh
```bash
curl http://localhost:8085/hello
curl http://localhost/api/hello
curl http://localhost/api/student
curl http://localhost/api/students-db
```
