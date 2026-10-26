# 🪣 5. Object Storage Server (`object-storage-server`)

> **Thành viên phụ trách:** Thành viên 3 (Security, Storage & DNS Lead)  
> **Container Name:** `object-storage-server` (API Port `9000:9000`, Console Port `9001:9001`)  
> **Network Aliases (`cloud-net`):** `minio`, `storage`, `minio.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ lưu trữ đối tượng phi cấu trúc chuẩn S3 (tương tự **Amazon S3**) sử dụng **MinIO**. Dữ liệu được lưu bền vững qua volume `./object-storage-server/data:/data`.

## 2. Thông Tin Đăng Nhập
- **MinIO Console UI:** `http://localhost:9001`
- **S3 API Endpoint:** `http://localhost:9000`
- **Username / Password:** `minioadmin` / `minioadmin`

## 3. Nhiệm Vụ Thực Hiện & Demo
1. **Phần Cơ bản (#5):**
   - Đăng nhập `http://localhost:9001`.
   - Tạo bucket tên **`demo`**.
   - Upload file `web-frontend-server/html/index.html` vào bucket `demo`.
2. **Phần Mở rộng (#5 - 0.5 điểm):**
   - Tạo bucket tên **`profile-pics`**, vào phần **Manage → Access Policy** chuyển thành **`Public`**.
   - Upload ảnh đại diện **`avatar.jpg`** và mở đường dẫn public trực tiếp trên trình duyệt: `http://localhost:9000/profile-pics/avatar.jpg`.
   - Tạo thêm bucket tên **`documents`** và upload file **PDF báo cáo** của nhóm.
