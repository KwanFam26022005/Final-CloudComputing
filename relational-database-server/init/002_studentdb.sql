-- =============================================================================
-- MỞ RỘNG #3 (0.5 điểm): Tạo CSDL studentdb và bảng students
-- TODO [Thành viên 2]: Cập nhật MSSV, Họ tên, Ngày sinh, Chuyên ngành của nhóm
-- =============================================================================
CREATE DATABASE IF NOT EXISTS studentdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE studentdb;

CREATE TABLE IF NOT EXISTS students (
  id INT PRIMARY KEY AUTO_INCREMENT,
  student_id VARCHAR(10) NOT NULL,
  fullname VARCHAR(100) NOT NULL,
  dob DATE NOT NULL,
  major VARCHAR(50) NOT NULL
);

INSERT INTO students (student_id, fullname, dob, major) VALUES
  ('SV001', 'Nguyen Van A (Member 1)', '2005-02-26', 'Cloud Computing'),
  ('SV002', 'Tran Thi B (Member 2)',   '2005-05-14', 'Software Engineering'),
  ('SV003', 'Le Van C (Member 3)',     '2005-08-20', 'Cyber Security'),
  ('SV004', 'Pham Thi D (Member 4)',   '2005-11-10', 'Data Science');
