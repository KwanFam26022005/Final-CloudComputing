-- =============================================================================
-- KỊCH BẢN THỰC HÀNH CRUD TỰ ĐỘNG - MỞ RỘNG #3 (0.5 ĐIỂM)
-- Thành viên phụ trách: Thành viên 2 (Backend & Data Lead)
-- CSDL: studentdb | Bảng: students
-- =============================================================================

USE studentdb;

-- -----------------------------------------------------------------------------
-- [DỌN DẸP AN TOÀN TRƯỚC KHI CHẠY (IDEMPOTENT)]
-- -----------------------------------------------------------------------------
DELETE FROM students WHERE student_id = 'SV005';

-- -----------------------------------------------------------------------------
-- BƯỚC 1: READ (TRUY VẤN DỮ LIỆU BAN ĐẦU)
-- -----------------------------------------------------------------------------
SELECT '>>> BƯỚC 1: TRUY VẤN DANH SÁCH SINH VIÊN HIỆN CÓ (READ BAN ĐẦU)' AS 'THAO TÁC CRUD';
SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major 
FROM students 
ORDER BY id ASC;

-- -----------------------------------------------------------------------------
-- BƯỚC 2: CREATE (THÊM MỚI BẢN GHI SINH VIÊN THỨ 5 - SV005)
-- -----------------------------------------------------------------------------
SELECT '>>> BƯỚC 2: THÊM MỚI SINH VIÊN SV005 (CREATE / INSERT)' AS 'THAO TÁC CRUD';
INSERT INTO students (student_id, fullname, dob, major) 
VALUES ('SV005', 'Hoang Minh E', '2005-03-19', 'Information Systems');

-- Kiểm tra kết quả sau khi INSERT:
SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major 
FROM students 
WHERE student_id = 'SV005';

-- -----------------------------------------------------------------------------
-- BƯỚC 3: UPDATE (CẬP NHẬT CHUYÊN NGÀNH VÀ HỌ TÊN CỦA SV005)
-- -----------------------------------------------------------------------------
SELECT '>>> BƯỚC 3: CẬP NHẬT CHUYÊN NGÀNH CỦA SV005 (UPDATE)' AS 'THAO TÁC CRUD';
UPDATE students 
SET major = 'Cloud Computing & DevOps', fullname = 'Hoang Minh E (Updated)' 
WHERE student_id = 'SV005';

-- Kiểm tra kết quả sau khi UPDATE:
SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major 
FROM students 
WHERE student_id = 'SV005';

-- -----------------------------------------------------------------------------
-- BƯỚC 4: DELETE (XÓA SINH VIÊN SV005 VỪA TẠO)
-- -----------------------------------------------------------------------------
SELECT '>>> BƯỚC 4: XÓA SINH VIÊN SV005 KHỎI HỆ THỐNG (DELETE)' AS 'THAO TÁC CRUD';
DELETE FROM students 
WHERE student_id = 'SV005';

-- -----------------------------------------------------------------------------
-- KẾT THÚC: TRUY VẤN LẠI TOÀN BẢNG ĐỂ CHỨNG MINH ĐÃ HOÀN TẤT CRUD
-- -----------------------------------------------------------------------------
SELECT '>>> TRẠNG THÁI CUỐI CÙNG SAU KHI THỰC HIỆN TRỌN BỘ CRUD' AS 'THAO TÁC CRUD';
SELECT id, student_id, fullname, CAST(dob AS CHAR) AS dob, major 
FROM students 
ORDER BY id ASC;
