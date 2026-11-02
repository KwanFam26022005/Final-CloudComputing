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
- **`provisioning/dashboards/dashboard.yml`**: Provider đọc mọi file `*.json` trong thư mục này. Bật `allowUiUpdates: true` để có thể bấm **Save** trên UI với dashboard được provisioning.
- **`provisioning/dashboards/node-exporter-full-1860.json`**: Dashboard **Node Exporter Full** (ID `1860`, tải từ grafana.com) được nạp sẵn để không bị mất khi tạo lại container (Cơ bản #8).
- **`provisioning/dashboards/system-health-52300140.json`**: Dashboard **`System Health of 52300140`** phục vụ **Mở rộng #8 (0.5 điểm)** gồm đúng 3 biểu đồ yêu cầu:
  1. **CPU Usage (%)**: `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)`
  2. **Memory Usage (%)**: `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
  3. **Network Traffic (RX/TX)**: `rate(node_network_receive_bytes_total{device!="lo"}[1m])` và `rate(node_network_transmit_bytes_total{device!="lo"}[1m])`

## 3. Hướng Dẫn Sử Dụng & Tùy Chỉnh
1. Mở trình duyệt tại: `http://localhost:3000`
2. Đăng nhập với tài khoản: **`admin` / `admin`**
3. **Phần Cơ bản (#8):**
   - **Connections → Data sources → Prometheus → Save & test** phải báo *Successfully queried the Prometheus API*.
   - Mở dashboard **Node Exporter Full** (đã nạp sẵn). Nếu cần minh họa thao tác import: **Dashboards → New → Import**, nhập ID **`1860`** → chọn Datasource `Prometheus` → **Import** (chọn *Import (Overwrite)* nếu báo trùng uid).
4. **Phần Mở rộng (#8 - 0.5 điểm):**
   - Vào **Dashboards**, mở **`System Health of 52300140`**, chụp ảnh đủ 3 biểu đồ.
   - Nếu chỉnh sửa panel trên UI: bấm **Save**, sau đó **Export → Export as JSON** và chép đè vào `provisioning/dashboards/system-health-52300140.json` rồi commit, để thay đổi không bị file provisioning ghi đè.
