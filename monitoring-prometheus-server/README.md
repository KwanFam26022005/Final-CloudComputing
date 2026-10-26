# 📈 7. Monitoring Prometheus Server (`monitoring-prometheus-server`)

> **Thành viên phụ trách:** Thành viên 4 (Observability & Cloud Ops Lead)  
> **Container Name:** `monitoring-prometheus-server` (Port `9090:9090`) + `monitoring-node-exporter-server` (Port `9100:9100`)  
> **Network Aliases (`cloud-net`):** `prometheus`, `monitor`, `node-exporter`

---

## 1. Mục Đích & Vai Trò
Mô phỏng hệ thống thu thập và truy vấn chỉ số giám sát hạ tầng đám mây (tương tự **Amazon CloudWatch Metrics**). Prometheus định kỳ thu thập (scrape) dữ liệu mỗi `15s` từ các target được khai báo.

## 2. Cấu Hình Scrape Jobs (`prometheus.yml`)
1. **`job_name: 'node'`** *(Cơ bản #7)*: Thu thập chỉ số phần cứng/container từ `monitoring-node-exporter-server:9100`.
2. **`job_name: 'web'`** *(Mở rộng #7 - 0.5 điểm)*: Thu thập trạng thái hoạt động trực tiếp từ `web-frontend-server:80` (qua endpoint `/metrics`).

## 3. Lệnh Kiểm Thử & Chụp Ảnh Báo Cáo
1. Mở trình duyệt tại: `http://localhost:9090/targets`
   - Xác nhận cả 2 target `monitoring-node-exporter-server:9100` và `web-frontend-server:80` đều có trạng thái **`UP`** màu xanh.
2. Mở tab **Graph** (`http://localhost:9090/graph`), nhập biểu thức PromQL:
   - `node_cpu_seconds_total`
   - `web_frontend_up`
