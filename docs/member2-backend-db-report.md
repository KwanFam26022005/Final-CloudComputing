# Báo Cáo Chi Tiết Phần Việc Của Thành Viên 2: Backend & Data Lead

> **Họ tên & MSSV:** `[Điền Họ tên & MSSV Thành viên 2]`  
> **Vai trò:** Backend & Data Lead  
> **Các Server sở hữu:** `application-backend-server` (Port `8085:8081`) và `relational-database-server` (Port `3306:3306`)  
> **Tổng số điểm trực tiếp:** **2.0 / 10.0 Điểm** (1.0đ Cơ bản + 1.0đ Mở rộng)  
> **Nhánh phát triển Git:** `feat/m2-backend-data-lead`  
> **Image Docker Hub:** `<dockerhub_user>/myminicloud-app:latest`

---

## BẢNG TỔNG KẾT ĐÓNG GÓP & MỨC ĐỘ HOÀN THÀNH

| Hạng mục | Điểm | Loại yêu cầu | Nội dung hoàn thành | Kết quả nghiệm thu |
| :--- | :---: | :--- | :--- | :--- |
| **Cơ bản #2** | `0.5đ` | Application Backend | API `/hello` (`Hello from App Server!`) và `/secure` xác thực JWT RS256 Bearer Token từ Keycloak qua JWKS. | Đạt `200 OK` cả trực tiếp cổng `8085` và qua Proxy Gateway cổng `80`. |
| **Cơ bản #3** | `0.5đ` | Relational Database | Cấu hình MariaDB 11, tự động nạp `001_init.sql` tạo CSDL `minicloud`, bảng `notes` và bản ghi `'Hello from MariaDB!'`. | Truy vấn SQL thành công, trả về đúng bản ghi mẫu. |
| **Mở rộng #2** | `0.5đ` | Backend API JSON | Tạo `students.json` chứa 5 sinh viên đầy đủ trường (`id`, `name`, `major`, `gpa`). Viết API `GET /student`. | Trả về JSON 5 sinh viên qua cổng `8085/student`, `/api/student` và `/student/`. |
| **Mở rộng #3** | `0.5đ` | Database CRUD & API | Tạo CSDL `studentdb`, bảng `students`, script thực hành CRUD tự động `crud_practice.sql` và bộ REST API CRUD `/students-db` kết nối MariaDB. | Thực thi trọn vẹn chu trình `SELECT` $\rightarrow$ `INSERT` $\rightarrow$ `UPDATE` $\rightarrow$ `DELETE` qua cả SQL và HTTP REST API. |
| **Docker Hub** | `--` | Đóng gói & Hạ tầng | Viết `Dockerfile` tối ưu hóa (Python Alpine), build và push image `myminicloud-app` lên Docker Hub. | Image public sẵn sàng kéo về triển khai trên AWS EC2. |

---

## CHƯƠNG 3: CẤU HÌNH HẠ TẦNG & MÃ NGUỒN CỦA THÀNH VIÊN 2

### 3.4. Cấu hình Application Backend Server (`application-backend-server`)

#### 3.4.1. Kiến trúc module và cấu trúc thư mục
Tầng Application Backend được xây dựng bằng ngôn ngữ **Python 3.11** sử dụng Microframework **Flask**, đóng vai trò là API xử lý nghiệp vụ trung tâm kết nối giữa người dùng, hệ thống xác thực tập trung Keycloak và cơ sở dữ liệu quan hệ MariaDB:

```text
application-backend-server/
├── Dockerfile              # Đóng gói image nhẹ dựa trên python:3.11-alpine
├── requirements.txt        # Khai báo phụ thuộc: flask, pymysql, requests, python-jose
├── app.py                  # Mã nguồn chính chứa toàn bộ REST API endpoints
├── students.json           # File cấu hình tĩnh lưu danh sách 5 sinh viên (Mở rộng #2)
├── tests/                  # Bộ kiểm thử tự động Unit Tests (TDD)
│   ├── __init__.py
│   └── test_app.py
└── README.md               # Hướng dẫn chi tiết cách build, chạy và test module
```

#### 3.4.2. Đóng gói Container (`Dockerfile` & `requirements.txt`)
File `Dockerfile` sử dụng base image `python:3.11-alpine` giúp giảm thiểu tối đa kích thước image (chỉ khoảng 60MB), rút ngắn thời gian build và tiết kiệm băng thông khi push lên Docker Hub:

```dockerfile
FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py students.json ./
EXPOSE 8081
CMD ["python", "app.py"]
```

File `requirements.txt` chỉ bao gồm 4 thư viện chuẩn bám sát yêu cầu đề bài:
```text
flask==3.0.0
requests==2.31.0
python-jose[cryptography]==3.3.0
pymysql==1.1.1
```

#### 3.4.3. Giải thích mã nguồn chính (`app.py`)
1. **Quản lý đường dẫn tĩnh an toàn:** `STUDENTS_JSON_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "students.json")` đảm bảo backend luôn đọc đúng file JSON dù ứng dụng được khởi chạy từ bất kỳ thư mục hiện hành (working directory) nào.
2. **Cơ chế xác thực OIDC JWT linh hoạt (`GET /secure`):**
   * Hàm `extract_realm_from_token(token)` đọc unverified claim `iss` từ token để nhận diện chính xác Realm phát hành (`master` hoặc Realm sinh viên `realm_<mssv>`).
   * Hàm `get_jwks_for_realm(realm_name)` tự động kết nối qua mạng nội bộ `http://authentication-identity-server:8080/realms/{realm_name}/protocol/openid-connect/certs` để lấy khóa công khai JWKS, đồng thời lưu bộ nhớ đệm (cache 10 phút) nhằm tối ưu hiệu năng và tránh gửi request dồn dập sang Keycloak.
   * Giải mã và kiểm tra chữ ký RS256 của token, trích xuất `preferred_username` của sinh viên.
3. **Bộ REST API CRUD tương tác MariaDB (`/students-db`):**
   * `GET /students-db`: Kết nối MariaDB qua cổng nội bộ `3306`, truy vấn danh sách sinh viên với định dạng `dob` dạng chuỗi `YYYY-MM-DD`.
   * `POST /students-db`: Tiếp nhận body JSON, kiểm tra định dạng qua hàm `validate_student_payload()`, thực thi `INSERT INTO students`. Nếu trùng `student_id` sẽ bắt mã lỗi `1062` và trả về HTTP `409 Conflict`.
   * `PUT /students-db/<student_id>`: Cập nhật thông tin sinh viên theo mã `student_id`, trả về HTTP `404` nếu mã sinh viên không tồn tại.
   * `DELETE /students-db/<student_id>`: Xóa sinh viên khỏi cơ sở dữ liệu.

---

### 3.5. Cấu hình Relational Database Server (`relational-database-server`)

#### 3.5.1. Cơ chế tự động khởi tạo (Entrypoint Init Scripts)
Hệ thống sử dụng container **MariaDB 11**. Toàn bộ các script SQL đặt trong thư mục `relational-database-server/init/` được mount vào thư mục `/docker-entrypoint-initdb.d:ro` của container. Khi container khởi động lần đầu tiên (volume dữ liệu trống), MariaDB sẽ tự động thực thi tuần tự các file `.sql` theo thứ tự bảng chữ cái:

1. **`001_init.sql` (Cơ bản #3):**
   ```sql
   CREATE DATABASE IF NOT EXISTS minicloud;
   USE minicloud;
   CREATE TABLE IF NOT EXISTS notes (
     id INT AUTO_INCREMENT PRIMARY KEY,
     title VARCHAR(100) NOT NULL,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   INSERT INTO notes (title) VALUES ('Hello from MariaDB!');
   ```
2. **`002_studentdb.sql` (Mở rộng #3):**
   ```sql
   CREATE DATABASE IF NOT EXISTS studentdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   USE studentdb;
   CREATE TABLE IF NOT EXISTS students (
     id INT PRIMARY KEY AUTO_INCREMENT,
     student_id VARCHAR(10) NOT NULL UNIQUE,
     fullname VARCHAR(100) NOT NULL,
     dob DATE NOT NULL,
     major VARCHAR(50) NOT NULL
   );
   INSERT INTO students (student_id, fullname, dob, major) VALUES
     ('SV001', 'Nguyen Van A (Member 1)', '2005-02-26', 'Cloud Computing'),
     ('SV002', 'Tran Thi B (Member 2)',   '2005-05-14', 'Software Engineering'),
     ('SV003', 'Le Van C (Member 3)',     '2005-08-20', 'Cyber Security'),
     ('SV004', 'Pham Thi D (Member 4)',   '2005-11-10', 'Data Science')
   ON DUPLICATE KEY UPDATE fullname=VALUES(fullname), dob=VALUES(dob), major=VALUES(major);
   ```

---

## CHƯƠNG 4: KẾT QUẢ KIỂM THỬ & MINH CHỨNG THỰC NGHIỆM

### 4.1. Kiểm thử phần Cơ bản của Thành viên 2

#### 4.1.3. Kiểm thử Application Backend Server (`/hello` & `/secure`)
* **Kiểm thử trực tiếp cổng 8085:**
  ```bash
  curl -s http://localhost:8085/hello
  ```
  *Kết quả trả về:* `{"message":"Hello from App Server!"}`
* **Kiểm thử qua API Gateway Proxy (cổng 80):**
  ```bash
  curl -s http://localhost/api/hello
  ```
  *Kết quả trả về:* `{"message":"Hello from App Server!"}`

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 1: Lệnh curl kiểm tra /hello trực tiếp và qua proxy]**

* **Kiểm thử bảo mật OIDC (`/secure`):**
  * Không có token:
    ```bash
    curl -s http://localhost/api/secure
    ```
    *Kết quả trả về:* `{"error":"Missing Bearer token"}` (HTTP 401).
  * Kèm Bearer Token lấy từ user `sv01` của Keycloak:
    ```bash
    curl -s -H "Authorization: Bearer <TOKEN>" http://localhost/api/secure
    ```
    *Kết quả trả về:* `{"client_id":"flask-app","message":"Secure resource OK","preferred_username":"sv01","realm":"realm_sv001"}` (HTTP 200).

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 2: Lệnh lấy token từ Keycloak và curl vào /api/secure thành công 200 OK]**

#### 4.1.4. Kiểm thử Relational Database Server (`minicloud.notes`)
* Chạy truy vấn SQL kiểm tra bảng `notes` trong database `minicloud`:
  ```bash
  docker exec -it relational-database-server mariadb -uroot -proot -e "USE minicloud; SHOW TABLES; SELECT * FROM notes;"
  ```
* *Kết quả hiển thị:* Bảng `notes` gồm cột `id`, `title`, `created_at` và có bản ghi `'Hello from MariaDB!'`.

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 3: Kết quả lệnh SELECT từ container MariaDB hiển thị Hello from MariaDB!]**

---

### 4.2. Kiểm thử phần Mở rộng của Thành viên 2

#### 4.2.2. [Mở rộng #2 - 0.5 điểm] API `/student` đọc danh sách sinh viên từ `students.json`
* Gọi kiểm tra qua các cổng:
  ```bash
  # Gọi trực tiếp Backend
  curl -s http://localhost:8085/student

  # Gọi qua API Gateway
  curl -s http://localhost/api/student

  # Gọi qua route riêng trên Gateway (/student/)
  curl -s http://localhost/student/
  ```
* *Kết quả:* Trả về định dạng JSON mảng gồm 5 sinh viên với đầy đủ 4 thuộc tính `id`, `name`, `major`, `gpa`.

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 4: Kết quả trả về của API /student hiển thị danh sách 5 sinh viên JSON]**

#### 4.2.3. [Mở rộng #3 - 0.5 điểm] CSDL `studentdb`, Thực hành CRUD & API `/students-db`

##### A. Thực hành chu trình CRUD tự động bằng SQL (`crud_practice.sql`)
Chạy file script chuyên dụng:
```bash
docker exec -i relational-database-server mariadb -uroot -proot < relational-database-server/crud_practice.sql
```
* **Bước 1 (READ):** Truy vấn danh sách 4 sinh viên khởi tạo (`SV001` đến `SV004`).
* **Bước 2 (CREATE):** Chèn sinh viên `SV005` (`Hoang Minh E`, `2005-03-19`, `Information Systems`).
* **Bước 3 (UPDATE):** Cập nhật ngành học của `SV005` thành `'Cloud Computing & DevOps'`.
* **Bước 4 (DELETE):** Xóa bản ghi `SV005` và kiểm tra lại bảng trở về trạng thái 4 sinh viên ban đầu.

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 5: Terminal hiển thị trọn vẹn kết quả chạy script crud_practice.sql qua 4 bước SELECT -> INSERT -> UPDATE -> DELETE]**

##### B. Thực hành CRUD qua REST API (`/api/students-db`)
* **1. READ (GET):**
  ```bash
  curl -s http://localhost/api/students-db
  ```
* **2. CREATE (POST):**
  ```bash
  curl -s -X POST http://localhost/api/students-db \
    -H "Content-Type: application/json" \
    -d '{"student_id":"SV888","fullname":"Nguyen Van Test","dob":"2005-08-18","major":"Cloud Engineering"}'
  ```
  *Kết quả HTTP 201 Created:* `{"message":"Student created successfully", ...}`
* **3. UPDATE (PUT):**
  ```bash
  curl -s -X PUT http://localhost/api/students-db/SV888 \
    -H "Content-Type: application/json" \
    -d '{"major":"DevOps & Cloud Architect"}'
  ```
  *Kết quả HTTP 200 OK:* `{"message":"Student updated successfully", ...}`
* **4. DELETE (DELETE):**
  ```bash
  curl -s -X DELETE http://localhost/api/students-db/SV888
  ```
  *Kết quả HTTP 200 OK:* `{"message":"Student deleted successfully","student_id":"SV888"}`

> 📷 **[CHÈN ẢNH CHỤP MÀN HÌNH MINH CHỨNG 6: Các lệnh curl thực hiện POST, PUT, DELETE trên /api/students-db]**

---

## HƯỚNG DẪN BUILD & PUSH DOCKER HUB (`myminicloud-app`)

Để hoàn tất tiêu chí bắt buộc về Docker Hub của Thành viên 2:
```bash
# 1. Đăng nhập Docker Hub trên máy Host
docker login

# 2. Build image gắn tag tên tài khoản Docker Hub của bạn
docker build -t <your_dockerhub_username>/myminicloud-app:latest ./application-backend-server

# 3. Push image lên Docker Hub
docker push <your_dockerhub_username>/myminicloud-app:latest

# 4. Kiểm tra trên trình duyệt: https://hub.docker.com/r/<your_dockerhub_username>/myminicloud-app
```
*(Lưu lại đường dẫn URL repo Docker Hub để Thành viên 4 tổng hợp đưa vào Phụ lục B của Báo cáo).*
