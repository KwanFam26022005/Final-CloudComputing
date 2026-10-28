# 🧭 6. Internal DNS Server (`internal-dns-server`)

> **Thành viên phụ trách:** Thành viên 3 (Security, Storage & DNS Lead)  
> **Container Name:** `internal-dns-server` (Port `1053:53/udp`, `1053:53/tcp`)  
> **Network Aliases (`cloud-net`):** `dns`, `dns-server`, `ns.cloud.local`

---

## 1. Mục Đích & Vai Trò
Mô phỏng dịch vụ phân giải tên miền nội bộ Private Hosted Zone (tương tự **Amazon Route 53 Private DNS**) sử dụng **ISC Bind9**, quản lý vùng tên miền (zone) **`cloud.local`**.

## 2. Danh Sách Bản Ghi Trong `db.cloud.local`
| Tên miền đầy đủ (FQDN) | Loại | Địa chỉ IP ánh xạ | Hạng mục |
| :--- | :-: | :---: | :--- |
| `ns.cloud.local` | `A` | `127.0.0.1` | Name Server |
| `web-frontend-server.cloud.local` | `A` | `10.10.10.10` | **Cơ bản #6** |
| `app-backend.cloud.local` | `A` | `10.10.10.20` | **Mở rộng #6** |
| `minio.cloud.local` | `A` | `10.10.10.30` | **Mở rộng #6** |
| `keycloak.cloud.local` | `A` | `10.10.10.40` | **Mở rộng #6** |

## 3. Lệnh Kiểm Thử Phân Giải DNS (`dig`)
```bash
# Cách 1: Chạy từ máy Host (Linux / macOS / EC2 Ubuntu)
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local +short
dig @127.0.0.1 -p 1053 app-backend.cloud.local +short
dig @127.0.0.1 -p 1053 minio.cloud.local +short
dig @127.0.0.1 -p 1053 keycloak.cloud.local +short

# Cách 2: Chạy qua Docker container trong mạng cloud-net (Chạy tốt trên cả Windows PowerShell)
docker run --rm --network cloud-net internetsystemsconsortium/bind9:9.18 sh -c '
  dig @dns-server web-frontend-server.cloud.local +short
  dig @dns-server app-backend.cloud.local +short
  dig @dns-server minio.cloud.local +short
  dig @dns-server keycloak.cloud.local +short
'
```

## 4. Cấu hình local đã đối chiếu với image ISC

Ngày 27/10/2026, image `internetsystemsconsortium/bind9:9.18` đã chạy được trên
Docker Desktop nhưng trả REFUSED cho zone lab. Kiểm tra thực tế cho thấy
`/etc/bind/named.conf` mặc định trong image không include các file options/local
đang được mount từ dự án. `named-checkzone` hợp lệ riêng chưa chứng minh server
đang phục vụ zone đó.

Module bổ sung `named.conf` để include hai file cấu hình của dự án và
`compose.local.yml` để mount đúng entry point, đưa log ra Docker, khai báo
`linux/amd64` đúng metadata image hiện có. Mac ARM64 chạy image qua giả lập;
đây là biện pháp tương thích lab, không phải bản image ARM64 native.
Không sửa Compose chung hoặc IP zone để xử lý lỗi include.

Chạy từ thư mục gốc repository:

```bash
docker compose -f docker-compose.yml -f internal-dns-server/compose.local.yml config -q
docker compose -f docker-compose.yml -f internal-dns-server/compose.local.yml up -d --no-deps internal-dns-server
docker compose -f docker-compose.yml -f internal-dns-server/compose.local.yml ps internal-dns-server
```

Sau khi service chạy, kiểm tra config/zone và query:

```bash
docker exec internal-dns-server named-checkconf -z /etc/bind/named.conf
docker exec internal-dns-server named-checkzone cloud.local /etc/bind/db.cloud.local
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 app-backend.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 minio.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 keycloak.cloud.local A +norecurse
```

Chỉ nghiệm thu khi query trả NOERROR, authoritative answer và đúng IP từng record.
Thử thêm `+tcp` để kiểm tra cổng TCP. IP trong zone là dữ liệu lab; kiểm tra kết
nối đến service thật qua Docker aliases là phép kiểm tra riêng.
Mac có thể nhắc `.local` dành cho mDNS; bài lab giữ `cloud.local` theo đề và các
lệnh trên chỉ định rõ DNS server/cổng để tránh nhầm resolver.

Khi quản lý DNS theo cấu hình này, dùng cả hai file Compose. Duy sẽ điều phối việc
tích hợp cấu hình chính vào Compose chung ở giai đoạn bàn giao.
