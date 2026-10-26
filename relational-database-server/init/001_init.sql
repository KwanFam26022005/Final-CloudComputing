-- =============================================================================
-- CƠ BẢN #3: Khởi tạo CSDL minicloud và bảng notes lần đầu
-- =============================================================================
CREATE DATABASE IF NOT EXISTS minicloud;
USE minicloud;

CREATE TABLE IF NOT EXISTS notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO notes (title) VALUES ('Hello from MariaDB!');
