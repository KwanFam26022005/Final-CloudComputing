## Mô tả thay đổi (Description)
- **Thành viên thực hiện:** [Tên & MSSV]
- **Domain / Server phụ trách:** [VD: Member 1 - Web & API Gateway]
- **Hạng mục hoàn thành:**
  - [ ] Phần Cơ bản (Base 5.0đ)
  - [ ] Phần Mở rộng (Extended 5.0đ - Ghi rõ mục số mấy: #1 -> #10)
  - [ ] Tài liệu / Báo cáo

## Danh sách kiểm tra bắt buộc trước khi Merge (Checklist)
- [ ] Đã chạy `docker compose config` không báo lỗi cú pháp.
- [ ] Đã build và chạy thử bằng `docker compose up -d --build`.
- [ ] Không sửa đổi trái phép vào thư mục của thành viên khác nếu chưa thảo luận.
- [ ] Giữ nguyên thuộc tính `restart: unless-stopped` và `networks: [cloud-net]` (cùng `aliases`).
- [ ] Đã chạy script kiểm thử (`./scripts/verify-base.ps1` hoặc `./scripts/verify-extended.ps1`) và đính kèm kết quả bên dưới.

## Minh chứng kết quả kiểm thử (Test Evidence / Screenshots)
<!-- Dán log câu lệnh curl / dig / docker compose ps hoặc ảnh chụp màn hình vào đây -->
