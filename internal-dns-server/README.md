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

## 4. Cấu hình DNS đã tích hợp vào Compose gốc

Compose gốc mount `named.conf` để include đúng options/local/zone, chạy `named -g`
và khai báo `linux/amd64` theo image ISC đang dùng. Máy Mac ARM64 dùng giả lập;
EC2 x86_64 dùng cùng cấu hình theo kiến trúc native. Không cần ghép override.

```bash
docker compose config -q
docker compose up -d --no-deps internal-dns-server
docker exec internal-dns-server named-checkconf -z /etc/bind/named.conf
docker exec internal-dns-server named-checkzone cloud.local /etc/bind/db.cloud.local
dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 app-backend.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 minio.cloud.local A +norecurse
dig @127.0.0.1 -p 1053 keycloak.cloud.local A +norecurse
```

Kiểm thêm `+tcp`: mong đợi NOERROR, cờ aa và đúng bản ghi A. Đây là IP zone lab,
không tự trở thành IP thật của Docker container; kiểm thông mạng qua alias riêng.
`compose.local.yml` giữ tương thích lệnh cũ, không bắt buộc. Kiểm thử EC2 riêng sau
khi TV4 triển khai; không tự mở DNS public để hoàn thành bài lab nội bộ.

## Script task6

Từ gốc repo chạy `bash scripts/verify-task6.sh` hoặc `./scripts/verify-task6.ps1`.
Nội dung: `named-checkconf`, bốn A record qua UDP/TCP và ping tám alias theo đề.
Chuẩn bị đủ dịch vụ trước khi ping. Mỗi query phải NOERROR/aa/đúng IP để PASS.
