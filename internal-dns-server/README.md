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
