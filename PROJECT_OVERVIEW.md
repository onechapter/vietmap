# VietMap Mini - Dự án Cảnh báo Giao thông

## 📋 Mục tiêu & Mục đích

**Mục tiêu chính:** Xây dựng ứng dụng Flutter cảnh báo giao thông kiểu VietMap mini, giúp người dùng:
- Hiển thị bản đồ OpenStreetMap (OSM) với vị trí GPS realtime
- Cảnh báo camera phạt nguội khi đến gần (150m)
- Cảnh báo tốc độ khi vượt quá giới hạn
- Cảnh báo khu vực nguy hiểm (danger zones) và đường sắt
- Cảnh báo bằng giọng nói (TTS) và rung (vibration)
- Chạy nền trên Android để cảnh báo ngay cả khi màn hình tắt

**Mục đích:** Tạo một hệ thống hoàn chỉnh từ import dữ liệu OSM → xử lý → hiển thị → cảnh báo, với khả năng mở rộng và ổn định cao.

---

## 🏗️ Cấu trúc Dự án

```
VietMap2/
├── vietmap_app/              # Flutter app chính
│   ├── lib/
│   │   ├── main.dart         # Entry point, route tới MapScreen
│   │   ├── core/             # Utilities cốt lõi
│   │   │   ├── logger.dart   # AppLog wrapper
│   │   │   ├── retry.dart    # Exponential backoff retry
│   │   │   ├── grid_index.dart  # Spatial grid index (0.01° cells)
│   │   │   └── speed_smoother.dart  # EMA filter cho tốc độ
│   │   ├── data/             # Data layer
│   │   │   ├── cameras/      # Camera models, repository, cache, API service
│   │   │   └── rules/        # Speed/danger/railway rules
│   │   ├── features/          # Feature modules
│   │   │   └── map/          # MapScreen - màn hình chính
│   │   └── ui/               # UI components
│   │       ├── hud/          # Speedometer, speed limit sign
│   │       └── widgets/      # Camera bottom sheet
│   ├── assets/
│   │   ├── cameras/          # Sample camera JSON
│   │   ├── icons/            # Camera icon PNG
│   │   └── local_rules/      # Speed/danger/railway rules JSON
│   ├── tools/                # Scripts Dart
│   │   ├── osm_importer.dart      # Import từ Overpass API
│   │   ├── merge_speed_limit.dart # Merge speed từ nhiều nguồn
│   │   └── clean_datasets.dart    # Lọc và chuẩn hóa datasets
│   └── data_sources/         # Raw data từ OSM
│       ├── cameras/          # cameras.json
│       ├── railway/          # railway.json
│       ├── polygons/         # danger_zone.json
│       ├── speed/            # way_speed.json
│       └── final/            # Datasets đã clean (output)
│
├── server/                   # Fake Camera API (Node.js)
│   ├── index.js             # Express server, endpoint /cameras
│   ├── data/
│   │   └── cameras.json     # Sample camera data
│   └── package.json
│
└── .cursor/                  # Workflow management
    ├── config.json          # Phase config
    ├── workflow-state.json  # Trạng thái hiện tại
    └── tasks/               # Phase definitions
        ├── phase1.md       # Khởi tạo dự án
        ├── phase2.md        # Map + GPS
        ├── phase3.md        # Camera markers
        ├── phase4.md        # TTS warnings
        └── phase5.md        # Stability
```

---

## 🛠️ Công nghệ Sử dụng

### Flutter App
- **Framework:** Flutter 3.32.4 (Dart 3.8.1)
- **Map:** `flutter_map` 8.2.2 (OpenStreetMap tiles)
- **GPS:** `geolocator` 14.0.2
- **TTS:** `flutter_tts` 4.2.3
- **Vibration:** `vibration` 1.9.0
- **Database:** `sqflite` (SQLite cache cho cameras)
- **HTTP:** `http` package (fetch từ API)
- **Geometry:** `latlong2` 0.9.1 (tính khoảng cách Haversine)

### Backend/API
- **Runtime:** Node.js
- **Framework:** Express 4.19.2
- **CORS:** cors 2.8.5
- **Port:** 8080

### Data Pipeline
- **OSM Source:** Overpass API (multiple mirrors)
- **Format:** JSON
- **Processing:** Dart scripts (tools/*.dart)

---

## ✅ Đã Hoàn Thành

### Phase 1-5: Core Features
1. ✅ **Khởi tạo dự án Flutter** với dependencies đầy đủ
2. ✅ **MapScreen** với FlutterMap + OSM tiles
3. ✅ **GPS tracking realtime** (stream position, auto-restart nếu lỗi)
4. ✅ **Camera markers** hiển thị trên map (từ API/cache/assets)
5. ✅ **Cảnh báo camera** khi đến gần 150m (TTS + vibration)
6. ✅ **Speed smoothing** (EMA filter α=0.25)
7. ✅ **Speed limit detection** từ camera/rules
8. ✅ **Danger zone polygons** (point-in-polygon check)
9. ✅ **Railway crossing warnings** (300m radius)
10. ✅ **Grid spatial index** để tối ưu query (chỉ quét bucket lân cận)
11. ✅ **UI components:** Speedometer, Speed limit sign, Camera bottom sheet
12. ✅ **Fake Camera API** (Node.js server tại localhost:8080)
13. ✅ **SQLite cache** cho cameras (fallback khi API lỗi)
14. ✅ **OSM Importer** với:
    - Retry 3 lần (2s → 5s → 10s)
    - Mirror fallback (5 Overpass servers)
    - Content-type validation (chỉ chấp nhận JSON)
    - Error logging vào `importer_errors.jsonl`
    - Query: cameras, railway, danger polygons, speed limits
15. ✅ **Tools:** `merge_speed_limit.dart`, `clean_datasets.dart` (skeleton)

### Kiến trúc
- ✅ Repository pattern (CameraRepository, RuleRepository)
- ✅ Grid index cho spatial queries
- ✅ Exponential backoff retry
- ✅ Comprehensive logging (appLog)
- ✅ Error handling với fallback chain (API → Cache → Assets)

---

## 🚧 Chưa Hoàn Thành / Cần Làm

### Phase 2.5: Data Pipeline (Đang dở)
- ⚠️ **Chưa chạy lại importer** sau khi cập nhật code (cần chạy với bbox 8.8 104.5 11.8 107.5)
- ⚠️ **Chưa chạy merge_speed_limit.dart** để tạo `data_sources/final/speed_limit.json`
- ⚠️ **Chưa chạy clean_datasets.dart** để tạo datasets cuối trong `data_sources/final/`
- ⚠️ **Chưa có báo cáo** số lượng cameras/railway/danger/speed_limit sau khi clean

### Phase 3: Android Background Service
- ❌ **Chưa tạo LocationService.kt** (foreground service)
- ❌ **Chưa có foreground notification** để giữ service
- ❌ **Chưa có MethodChannel** để giao tiếp Flutter ↔ Android
- ❌ **Chưa có TTS ở nền** (Android service tự gọi TTS)
- ❌ **Chưa có sync state** khi Flutter restart

### Phase 4: Testing & Stabilization
- ❌ **Chưa stress test GPS** 1 giờ
- ❌ **Chưa test tắt màn hình** (background mode)
- ❌ **Chưa test mất mạng** (API fallback)
- ❌ **Chưa test bad data** (null speedLimit, invalid types)

### Phase 5: Advanced Features
- ❌ **Chưa có dark/light mode** tự động
- ❌ **Chưa có recording mode** (ghi lại đường đã đi)
- ❌ **Chưa có lịch sử tốc độ** theo thời gian
- ❌ **Chưa tối ưu polygon** (Douglas-Peucker compression)
- ❌ **Chưa có KD-tree offline** cho spatial index nâng cao

---

## 🚀 Cách Chạy Dự án

### 1. Fake Camera API (Node.js)
```bash
cd server
npm install
npm start
# Server chạy tại http://localhost:8080/cameras
```

### 2. Flutter App
```bash
cd vietmap_app
flutter pub get
flutter run --dart-define=CAMERA_API=http://localhost:8080
```

### 3. OSM Importer (Tạo datasets)
```bash
cd vietmap_app
dart run tools/osm_importer.dart --bbox 8.8 104.5 11.8 107.5
# Output: data_sources/cameras/cameras.json, railway.json, polygons/danger_zone.json, speed/way_speed.json
```

### 4. Merge Speed Limits
```bash
cd vietmap_app
dart run tools/merge_speed_limit.dart
# Output: data_sources/final/speed_limit.json
```

### 5. Clean Datasets
```bash
cd vietmap_app
dart run tools/clean_datasets.dart
# Output: data_sources/final/cameras.json, railway.json, danger_zone.json
```

---

## 📊 Trạng thái Workflow

**Current Phase:** `integrate_camera_api`  
**Completed Tasks:** `["phase1", "phase2", "phase3", "phase4", "phase5", "local_api", "integrate_camera_api"]`

**File:** `.cursor/workflow-state.json`

---

## 🔑 Điểm Quan Trọng

1. **Grid Index:** Dùng spatial grid (0.01° cells) để chỉ query bucket hiện tại + 8 lân cận, giảm từ O(n) xuống ~O(1) cho mỗi tick GPS.

2. **Fallback Chain:** API → SQLite Cache → Assets JSON. Đảm bảo app luôn có dữ liệu dù mất mạng.

3. **Cooldown System:** 
   - Camera: 40s
   - Danger/Railway: 60s
   - Speed: 40s
   Tránh spam cảnh báo.

4. **Speed Smoothing:** EMA filter để loại bỏ noise từ GPS, chỉ update UI khi thay đổi >0.5 km/h.

5. **OSM Importer:** Tự động retry + mirror fallback, không crash khi Overpass quá tải.

---

## 📝 Ghi Chú Kỹ Thuật

- **Camera Model:** `id` (String), `lat`, `lng`, `speedLimit` (int?), `type` (String)
- **Grid Index:** Cell size 0.01° (~1.1km), query neighborhood = current + 8 adjacent buckets
- **Distance Calculation:** Haversine formula từ `latlong2` package
- **TTS Language:** `vi-VN` (tiếng Việt)
- **Map Initial Zoom:** 15
- **GPS Update Interval:** 500-1000ms (high accuracy, distanceFilter: 5m)

---

## 🎯 Next Steps (Ưu tiên)

1. **Chạy lại data pipeline:** importer → merge → clean → báo cáo kết quả
2. **Android Background Service:** Tạo LocationService.kt với foreground notification
3. **Testing:** Stress test, background mode, network failure
4. **Polish:** Dark mode, recording, history

---

**Tạo bởi:** Cursor AI Agent  
**Ngày:** 2025-12-10  
**Version:** 1.0.0 (Work in Progress)

