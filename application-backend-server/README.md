# ⚙️ 2. Application Backend Server (`application-backend-server`)

> **Thành viên phụ trách:** Thành viên 2 (Backend & Data Lead)  
> **Container Name:** `application-backend-server` (Port `8085:8081`)  
> **Network Aliases (`cloud-net`):** `app`, `app-server`, `app-backend`, `app-backend.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng tầng xử lý nghiệp vụ Microservice / REST API viết bằng Python Flask, kết nối trực tiếp với MariaDB (`relational-database-server`) và xác thực người dùng qua Keycloak OIDC (`authentication-identity-server`).

## 2. Danh Sách API Endpoints
| Phương thức | Endpoint (Trực tiếp `:8085`) | Qua API Gateway (`:80`) | Hạng mục | Mô tả |
| :---: | :--- | :--- | :--- | :--- |
| `GET` | `/health` | `/api/health` | Kiểm tra | Trả về trạng thái hoạt động của Backend server (`status: ok`). |
| `GET` | `/hello` | `/api/hello` | Cơ bản #2 | Trả về JSON `{"message": "Hello from App Server!"}`. |
| `GET` | `/secure` | `/api/secure` | Cơ bản #2 & Mở rộng #4 | Kiểm tra chữ ký RS256 của JWT Bearer Token từ Keycloak và trả về `preferred_username`. |
| `GET` | `/student` | `/api/student` & `/student/` | Mở rộng #2 & #9 | Đọc danh sách 5 sinh viên từ file tĩnh `students.json`. |
| `GET` | `/students-db` | `/api/students-db` | Mở rộng #3 | Truy vấn trực tiếp bảng `students` trong CSDL `studentdb` trên MariaDB. |
| `POST` | `/students-db` | `/api/students-db` | Mở rộng #3 | Thêm mới sinh viên vào CSDL `studentdb.students` (body JSON). |
| `PUT` | `/students-db/<id>` | `/api/students-db/<id>` | Mở rộng #3 | Cập nhật thông tin sinh viên theo `student_id` (body JSON). |
| `DELETE` | `/students-db/<id>` | `/api/students-db/<id>` | Mở rộng #3 | Xóa sinh viên khỏi CSDL theo `student_id`. |

## 3. Lệnh Kiểm Thử Nhanh

### 3.1. Chạy Unit Tests tự động
```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

### 3.2. Gọi API kiểm thử (cổng trực tiếp hoặc qua proxy)
```bash
# Cơ bản
curl http://localhost:8085/hello
curl http://localhost/api/hello

# Mở rộng #2 (JSON file)
curl http://localhost:8085/student
curl http://localhost/api/student
curl http://localhost/student/

# Mở rộng #3 (MariaDB CRUD qua REST API)
# 1. READ
curl http://localhost/api/students-db

# 2. CREATE
curl -X POST http://localhost/api/students-db \
  -H "Content-Type: application/json" \
  -d '{"student_id":"SV005","fullname":"Hoang Minh E","dob":"2005-03-19","major":"Information Systems"}'

# 3. UPDATE
curl -X PUT http://localhost/api/students-db/SV005 \
  -H "Content-Type: application/json" \
  -d '{"major":"Cloud Computing & DevOps"}'

# 4. DELETE
curl -X DELETE http://localhost/api/students-db/SV005
```

## 4. Build & Push Image Docker Hub
```bash
docker build -t <dockerhub_user>/myminicloud-app:latest ./application-backend-server
docker push <dockerhub_user>/myminicloud-app:latest
```
