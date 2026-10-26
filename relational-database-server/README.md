# 🗄️ 3. Relational Database Server (`relational-database-server`)

> **Thành viên phụ trách:** Thành viên 2 (Backend & Data Lead)  
> **Container Name:** `relational-database-server` (Port `3306:3306`)  
> **Network Aliases (`cloud-net`):** `db`, `mysql`, `mariadb`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ Cơ sở dữ liệu quan hệ trên đám mây (tương tự Amazon RDS for MariaDB/MySQL). Tự động nạp toàn bộ kịch bản SQL trong thư mục `./init/` vào `/docker-entrypoint-initdb.d/` khi khởi tạo lần đầu.

## 2. Cấu Trúc Thư Mục
- `init/001_init.sql`: Tạo CSDL `minicloud`, bảng `notes` và bản ghi `'Hello from MariaDB!'` (**Cơ bản #3**).
- `init/002_studentdb.sql`: Tạo CSDL `studentdb`, bảng `students` (`id`, `student_id`, `fullname`, `dob`, `major`) và chèn sẵn 4 bản ghi (**Mở rộng #3**).

## 3. Lệnh Kiểm Thử & Thực Hành CRUD (Mở rộng #3)
```bash
# 1. Kiểm tra CSDL cơ bản (minicloud.notes)
docker exec -it relational-database-server mariadb -uroot -proot -e "USE minicloud; SHOW TABLES; SELECT * FROM notes;"

# 2. Kiểm tra CSDL mở rộng (studentdb.students) và thực hành CRUD
docker exec -it relational-database-server mariadb -uroot -proot -e "
  USE studentdb;
  SELECT * FROM students;
  INSERT INTO students (student_id, fullname, dob, major) VALUES ('SV005', 'Hoang Minh E', '2005-03-19', 'Information Systems');
  UPDATE students SET major = 'Cloud Native Architecture' WHERE student_id = 'SV005';
  SELECT * FROM students;
  DELETE FROM students WHERE student_id = 'SV005';
  SELECT * FROM students;
"
```
