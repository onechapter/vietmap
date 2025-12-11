# Phase 1 — Khởi tạo dự án Flutter + cấu trúc thư mục



## 🎯 Mục tiêu

- Tạo dự án Flutter mới (nếu chưa có)

- Cài dependencies cần thiết

- Tạo cấu trúc thư mục chuẩn cho dự án bản đồ + camera



## 🧩 Công việc cụ thể

1. Nếu chưa có dự án Flutter → chạy:
flutter create vietmap_app

2. Cài dependencies:


flutter pub add flutter_map geolocator latlong2 flutter_tts

3. Tạo cấu trúc thư mục:


lib/
core/
features/
map/
camera/
data/
cameras/
assets/
cameras/

4. Tạo file JSON camera mẫu:
`assets/cameras/sample.json`
5. Update pubspec.yaml để load asset.

## ✔ Kết quả mong đợi
- Build chạy được (không lỗi)
- Ready cho Phase 2

## ▶ Khi hoàn thành
Ghi vào `.cursor/workflow-state.json`:
- status = "success"
- completedTasks += ["phase1"]
- currentPhase = "phase2"
