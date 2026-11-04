# 🗄️ 3. Relational Database Server (`relational-database-server`)

> **Thành viên phụ trách:** Thành viên 2 (Backend & Data Lead)  
> **Container Name:** `relational-database-server` (Port `3306:3306`)  
> **Network Aliases (`cloud-net`):** `db`, `mysql`, `mariadb`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ Cơ sở dữ liệu quan hệ trên đám mây (tương tự Amazon RDS for MariaDB/MySQL). Tự động nạp toàn bộ kịch bản SQL trong thư mục `./init/` vào `/docker-entrypoint-initdb.d/` khi khởi tạo lần đầu.

## 2. Cấu Trúc Thư Mục
- `init/001_init.sql`: Tạo CSDL `minicloud`, bảng `notes` và bản ghi `'Hello from MariaDB!'` (**Cơ bản #3**).
- `init/002_studentdb.sql`: Tạo CSDL `studentdb`, bảng `students` (`id`, `student_id`, `fullname`, `dob`, `major`) với khóa duy nhất `UNIQUE` cho `student_id` và chèn sẵn 4 bản ghi (**Mở rộng #3**).
- `crud_practice.sql`: Kịch bản SQL tự động thực hiện trọn vẹn chu trình CRUD (`SELECT` $\rightarrow$ `INSERT` $\rightarrow$ `UPDATE` $\rightarrow$ `DELETE`) có tính idempotent.

## 3. Lệnh Kiểm Thử & Thực Hành CRUD (Mở rộng #3)

### 3.1. Kiểm tra CSDL cơ bản (minicloud.notes)
```bash
docker exec -it relational-database-server mariadb -uroot -proot -e "USE minicloud; SHOW TABLES; SELECT * FROM notes;"
```

### 3.2. Chạy tự động trọn bộ CRUD từ file `crud_practice.sql`
```bash
# Cách 1: Pipe file SQL trực tiếp vào container
docker exec -i relational-database-server mariadb -uroot -proot < relational-database-server/crud_practice.sql

# Cách 2: Chạy trực tiếp từ container Client trên mạng cloud-net
docker run --rm -i --network cloud-net mariadb:11 mariadb -h db -uroot -proot < relational-database-server/crud_practice.sql
```

### 3.3. Lệnh SQL chạy từng bước thủ công để chụp ảnh minh chứng
```bash
docker exec -it relational-database-server mariadb -uroot -proot -e "
  USE studentdb;
  SELECT '=== 1. SELECT BAN DAU ===';
  SELECT * FROM students;

  SELECT '=== 2. INSERT SV005 ===';
  INSERT INTO students (student_id, fullname, dob, major) VALUES ('SV005', 'Hoang Minh E', '2005-03-19', 'Information Systems');
  SELECT * FROM students WHERE student_id = 'SV005';

  SELECT '=== 3. UPDATE SV005 ===';
  UPDATE students SET major = 'Cloud Native Architecture' WHERE student_id = 'SV005';
  SELECT * FROM students WHERE student_id = 'SV005';

  SELECT '=== 4. DELETE SV005 ===';
  DELETE FROM students WHERE student_id = 'SV005';
  SELECT * FROM students;
"
```
