# 📊 8. Monitoring Grafana Dashboard Server (`monitoring-grafana-dashboard-server`)

> **Thành viên phụ trách:** Thành viên 4 (Observability & Cloud Ops Lead)  
> **Container Name:** `monitoring-grafana-dashboard-server` (Port `3000:3000`)  
> **Network Aliases (`cloud-net`):** `grafana`

---

## 1. Mục Đích & Vai Trò
Mô phỏng công cụ trực quan hóa dữ liệu giám sát đám mây (tương tự **Amazon CloudWatch Dashboards** / **Amazon Managed Grafana**). Kết nối trực tiếp tới nguồn dữ liệu `http://prometheus:9090` để vẽ biểu đồ thời gian thực.

## 2. Cấu Hình Tự Động Hóa (Grafana Provisioning)
Để tránh mất dữ liệu khi khởi động lại container hoặc khi triển khai lên AWS EC2, thư mục `provisioning/` đã được thiết lập sẵn:
- **`provisioning/datasources/prometheus.yml`**: Tự động kết nối Datasource `Prometheus` (`http://prometheus:9090`) làm mặc định.
- **`provisioning/dashboards/system-health-sv001.json`**: Tự động tạo sẵn Dashboard **`System Health of SV001`** phục vụ **Mở rộng #8 (0.5 điểm)** gồm đúng 3 biểu đồ yêu cầu:
  1. **CPU Usage (%)** (`node_cpu_seconds_total`)
  2. **Memory Usage** (`node_memory_MemAvailable_bytes`)
  3. **Network Traffic** (`node_network_receive_bytes_total`)

## 3. Hướng Dẫn Sử Dụng & Tùy Chỉnh
1. Mở trình duyệt tại: `http://localhost:3000`
2. Đăng nhập với tài khoản: **`admin` / `admin`**
3. **Phần Cơ bản (#8):** Vào **Dashboards → New → Import**, nhập ID **`1860`** (*Node Exporter Full*) → chọn Datasource `Prometheus` → **Import**.
4. **Phần Mở rộng (#8 - 0.5 điểm):**
   - Vào **Dashboards**, mở **`System Health of SV001`**.
   - *(Tùy chọn)* Sửa trường `"title": "System Health of <MSSV_THẬT>"` trong file `provisioning/dashboards/system-health-sv001.json` để hiển thị đúng MSSV của thành viên/nhóm.
