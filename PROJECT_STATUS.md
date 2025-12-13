# 📊 Tổng Hợp Trạng Thái Dự Án VietMap

**Ngày cập nhật:** 2025-01-XX  
**Version:** 1.0.0  
**Trạng thái:** Đang phát triển (Work in Progress)

---

## 📋 Mục Lục

1. [Tổng Quan Dự Án](#tổng-quan-dự-án)
2. [Các Phase Đã Hoàn Thành](#các-phase-đã-hoàn-thành)
3. [Các Phase Đang Phát Triển](#các-phase-đang-phát-triển)
4. [Các Phase Chưa Bắt Đầu](#các-phase-chưa-bắt-đầu)
5. [Kiến Trúc Hệ Thống](#kiến-trúc-hệ-thống)
6. [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)
7. [Tổng Kết](#tổng-kết)

---

## 🎯 Tổng Quan Dự Án

**VietMap Mini** là ứng dụng Flutter cảnh báo giao thông, giúp người dùng:
- Hiển thị bản đồ với vị trí GPS realtime
- Cảnh báo camera phạt nguội khi đến gần (150m)
- Cảnh báo tốc độ khi vượt quá giới hạn
- Cảnh báo khu vực nguy hiểm (danger zones) và đường sắt
- Cảnh báo bằng giọng nói (TTS) và rung (vibration)
- Chế độ mô phỏng (simulation mode) cho developer testing
- Navigation với voice guidance

---

## ✅ Các Phase Đã Hoàn Thành

### Phase 1: Khởi Tạo Dự Án ✅

**Mục tiêu:** Tạo dự án Flutter với cấu trúc thư mục chuẩn

**Đã hoàn thành:**
- ✅ Tạo dự án Flutter (`vietmap_app`)
- ✅ Cài đặt dependencies cần thiết:
  - `flutter_map` (bản đồ)
  - `geolocator` (GPS)
  - `latlong2` (tính toán địa lý)
  - `flutter_tts` (text-to-speech)
  - `vibration` / `vibration_standard` (rung)
  - `maplibre_gl` (vector tiles)
  - `rxdart` (reactive streams)
  - `flutter_riverpod` (state management)
- ✅ Tạo cấu trúc thư mục chuẩn:
  ```
  lib/
  ├── core/          # Utilities cốt lõi
  ├── features/      # Feature modules
  ├── data/          # Data layer
  └── ui/            # UI components
  ```
- ✅ Tạo file JSON camera mẫu
- ✅ Cấu hình `pubspec.yaml` để load assets

**Kết quả:** Dự án build thành công, sẵn sàng cho Phase 2

---

### Phase 2: Hiển Thị Bản Đồ + GPS ✅

**Mục tiêu:** Tạo màn hình map với OSM tiles và GPS tracking

**Đã hoàn thành:**
- ✅ Tạo `MapScreen` widget
- ✅ Tích hợp FlutterMap với OpenStreetMap tiles
- ✅ Implement GPS tracking realtime:
  - Xin quyền location
  - Stream position updates
  - Auto-restart nếu lỗi
- ✅ Hiển thị marker vị trí người dùng
- ✅ Camera follow mode (tự động zoom theo GPS)
- ✅ Chuyển sang MapLibre GL cho vector tiles support

**Kết quả:** App hiển thị map, marker user di chuyển theo GPS

---

### Phase 3: Nạp & Hiển Thị Camera ✅

**Mục tiêu:** Load và hiển thị camera phạt nguội trên bản đồ

**Đã hoàn thành:**
- ✅ Tạo `CameraModel` với các trường: `id`, `lat`, `lng`, `speedLimit`, `type`
- ✅ Tạo `CameraRepository` (extends `BaseRepository`)
- ✅ Load JSON từ assets: `data_sources/final/cameras.min.json`
- ✅ Render markers trên map:
  - Icon màu đỏ cho camera
  - Tooltip "Camera phạt nguội"
  - Bottom sheet khi tap vào camera
- ✅ Spatial indexing với `GridIndex` để tối ưu query
- ✅ Hỗ trợ nhiều nguồn dữ liệu:
  - API endpoint (Node.js server)
  - SQLite cache (fallback)
  - Assets JSON (fallback cuối)

**Kết quả:** Camera hiển thị trên bản đồ, query nhanh với spatial index

---

### Phase 4: Cảnh Báo Camera Bằng Âm Thanh ✅

**Mục tiêu:** Cảnh báo khi người dùng đến gần camera

**Đã hoàn thành:**
- ✅ Tạo `WarningEngine` với logic:
  - Tính khoảng cách user → camera (Haversine)
  - Kiểm tra trong bán kính 150m
  - Cooldown system (40s) để tránh spam
- ✅ Tích hợp TTS (Text-to-Speech):
  - Phát cảnh báo: "Sắp đến camera phạt nguội phía trước"
  - Ngôn ngữ: `vi-VN`
- ✅ Tích hợp Vibration:
  - Rung khi có cảnh báo
- ✅ Mở rộng cảnh báo cho:
  - **Railway crossings** (300m radius, 60s cooldown)
  - **Danger zones** (50m radius, 60s cooldown)
  - **Speed limits** (100m radius, 40s cooldown, vượt quá +5 km/h)
- ✅ Tạo `WarningManager` để quản lý warning stream
- ✅ Tạo `CooldownDb` (SQLite) để lưu cooldown state
- ✅ Speed smoothing với EMA filter (α=0.25)

**Kết quả:** App cảnh báo giọng nói và rung khi đến gần camera/railway/danger zone, không spam

---

### Phase 4.1: Repository Pattern ✅

**Mục tiêu:** Refactor code sử dụng Repository pattern

**Đã hoàn thành:**
- ✅ Tạo `BaseRepository<T>` abstract class:
  - Spatial indexing với `GridIndex`
  - Grid cache cho performance
  - Query nearby items trong radius
- ✅ Implement các repositories:
  - `CameraRepository` → `cameras.min.json`
  - `RailwayRepository` → `railway.min.json`
  - `DangerZoneRepository` → `danger_zone.min.json`
  - `SpeedLimitRepository` → `speed_limit.min.json`
- ✅ Hỗ trợ JSON fallback nếu MBTiles không có
- ✅ Error handling và logging đầy đủ
- ✅ Verbose logging cho debugging

**Kết quả:** Code clean, dễ maintain, dễ test

---

### Phase 4.2: Warning Engine với Vector Tiles ✅

**Mục tiêu:** Xây dựng engine cảnh báo dựa trên vector tiles data

**Đã hoàn thành:**
- ✅ `WarningEngine` query features từ repositories
- ✅ Tính khoảng cách từ user position đến features
- ✅ Trigger warnings khi:
  - User vào danger zone polygon (point-in-polygon check)
  - User gần railway crossing < 300m
  - User gần camera < 150m
  - User vượt tốc độ (so với speed_limit)
- ✅ Tích hợp với TTS và vibration system
- ✅ Anti-spam logic (cooldown per feature)
- ✅ Reset cooldown trong simulation mode
- ✅ Verbose logging cho mọi warning event

**Kết quả:** Warning engine hoạt động đầy đủ với tất cả loại cảnh báo

---

### Phase 4.3: UI Enhancements ✅

**Mục tiêu:** Cải thiện UI với interactive features

**Đã hoàn thành:**
- ✅ `Speedometer` widget hiển thị tốc độ hiện tại
- ✅ `SpeedLimitSign` widget hiển thị giới hạn tốc độ
- ✅ `CameraBottomSheet` hiển thị chi tiết camera khi tap
- ✅ HUD (Heads-Up Display) trên map:
  - Tốc độ hiện tại
  - Giới hạn tốc độ
  - Warning counters (cam, speed, danger, rail)
- ✅ Map camera follow mode với auto-zoom
- ✅ Smooth map updates khi GPS di chuyển

**Kết quả:** UI đẹp, responsive, hiển thị đầy đủ thông tin

---

### Phase 5: Ổn Định & Xử Lý Lỗi ✅

**Mục tiêu:** Ổn định app, xử lý edge cases

**Đã hoàn thành:**
- ✅ Guard code vào tất cả file
- ✅ Comprehensive logging với `appLog`
- ✅ Try/catch toàn app
- ✅ Exponential backoff retry cho API calls
- ✅ Fallback chain: API → Cache → Assets
- ✅ Error handling cho:
  - GPS permission denied
  - Network errors
  - JSON parse errors
  - Missing assets
- ✅ Build release thành công (Android)

**Kết quả:** App chạy ổn định, handle lỗi tốt

---

### Phase 6: Simulation Mode (Developer Tool) ✅

**Mục tiêu:** Tạo chế độ mô phỏng để test cảnh báo

**Đã hoàn thành:**
- ✅ Tạo `LocationController` (unified location stream):
  - Sử dụng `BehaviorSubject` từ `rxdart`
  - Hỗ trợ real GPS và fake/simulated locations
  - Single source of truth cho tất cả location updates
- ✅ Tạo `LocationSimulator`:
  - Smooth movement dọc theo route
  - Linear interpolation giữa các điểm
  - Configurable speed (5-120 km/h)
- ✅ Tạo `RouteSimulatorService`:
  - Tính route từ start → end (OSRM API)
  - Simulate movement dọc route
  - Auto-zoom map khi bắt đầu
- ✅ Tạo `FakeLocationService`:
  - Set location tĩnh
  - Update location thủ công
- ✅ Tạo `SimulationScreen`:
  - UI chọn start/end points
  - Speed slider
  - Start/Pause/Stop controls
  - Ghost car renderer
- ✅ Tạo `DebugScreen`:
  - Query nearby features
  - Fake location controls
  - Route simulator controls
  - Warning history
  - Repository stats
- ✅ Tích hợp với `WarningEngine`:
  - WarningEngine nghe từ `LocationController.stream`
  - Reset cooldown trong simulation mode
  - Warnings trigger đúng trong simulation

**Kết quả:** Developer có thể test cảnh báo mà không cần di chuyển thật

---

### Phase 7: Navigation System ✅

**Mục tiêu:** Tích hợp navigation với voice guidance

**Đã hoàn thành:**
- ✅ Tạo `RouteEngine`:
  - Request route từ OSRM API
  - Parse route steps
  - Offline route cache
- ✅ Tạo `NavigationEngine`:
  - Track progress dọc route
  - Detect reroute khi off-route
  - Offline reroute engine
- ✅ Tạo `VoiceGuidanceEngine`:
  - TTS instructions cho từng maneuver
  - Pre-announcement (200m trước)
  - Language: `vi-VN`
- ✅ Tạo `NavigationScreen`:
  - Hiển thị route polyline
  - Maneuver banner
  - Navigation bottom bar
  - Distance to next turn
- ✅ Tích hợp với `MapScreen`:
  - Show route khi navigation active
  - Camera follow mode trong navigation

**Kết quả:** Navigation hoạt động với voice guidance đầy đủ

---

### Phase 8: Data Pipeline ✅

**Mục tiêu:** Import và xử lý dữ liệu từ OSM

**Đã hoàn thành:**
- ✅ Tạo `osm_importer.dart`:
  - Query từ Overpass API (5 mirrors)
  - Retry 3 lần với exponential backoff
  - Content-type validation
  - Error logging vào `importer_errors.jsonl`
  - Query: cameras, railway, danger polygons, speed limits
- ✅ Tạo `merge_speed_limit.dart`:
  - Merge speed từ nhiều nguồn
  - Output: `speed_limit.json`
- ✅ Tạo `clean_datasets.dart`:
  - Lọc và chuẩn hóa datasets
  - Validate schema
  - Output: `data_sources/final/*.json`
- ✅ Tạo `fix_and_minify.dart`:
  - Minify JSON files
  - Output: `*.min.json` cho assets
- ✅ Tạo `generate_vector_tiles.dart`:
  - Convert GeoJSON → MBTiles (Tippecanoe)
  - Output: `vietmap.mbtiles`
- ✅ Tạo `validate_schema.dart`:
  - Validate JSON schema
  - Check required fields

**Kết quả:** Data pipeline hoàn chỉnh từ OSM → JSON → MBTiles

---

## 🚧 Các Phase Đang Phát Triển

### Phase 4.4: UI Enhancements với Vector Tiles (Một phần)

**Đang làm:**
- ⚠️ Feature info bottom sheet (đã có cho camera, chưa có cho danger/railway)
- ⚠️ Layer toggle UI (chưa có)
- ⚠️ Tile loading indicator (chưa có)
- ⚠️ Performance optimization (một phần)

**Cần làm:**
- [ ] Bottom sheet cho danger zones và railway
- [ ] Layer toggle panel
- [ ] Loading indicator khi tiles đang load
- [ ] Performance profiling và optimization

---

## ❌ Các Phase Chưa Bắt Đầu

### Phase 9: Android Background Service

**Mục tiêu:** Chạy cảnh báo ở background khi màn hình tắt

**Chưa làm:**
- [ ] Tạo `LocationService.kt` (foreground service)
- [ ] Foreground notification để giữ service
- [ ] MethodChannel để giao tiếp Flutter ↔ Android
- [ ] TTS ở nền (Android service tự gọi TTS)
- [ ] Sync state khi Flutter restart
- [ ] Battery optimization handling

**Ưu tiên:** Cao (cần cho production)

---

### Phase 10: Testing & Stabilization

**Mục tiêu:** Đảm bảo app ổn định và không có bug

**Chưa làm:**
- [ ] Stress test GPS 1 giờ
- [ ] Test tắt màn hình (background mode)
- [ ] Test mất mạng (API fallback)
- [ ] Test bad data (null speedLimit, invalid types)
- [ ] Unit tests cho repositories
- [ ] Integration tests cho warning engine
- [ ] Widget tests cho UI components
- [ ] Performance tests (memory, CPU, battery)

**Ưu tiên:** Cao (cần cho production)

---

### Phase 11: Advanced Features

**Mục tiêu:** Thêm tính năng nâng cao

**Chưa làm:**
- [ ] Dark/light mode tự động
- [ ] Recording mode (ghi lại đường đã đi)
- [ ] Lịch sử tốc độ theo thời gian
- [ ] Tối ưu polygon (Douglas-Peucker compression)
- [ ] KD-tree offline cho spatial index nâng cao
- [ ] Custom map styles
- [ ] Offline map download
- [ ] User preferences (settings screen đã có, chưa implement features)

**Ưu tiên:** Thấp (nice to have)

---

## 🏗️ Kiến Trúc Hệ Thống

### Cấu Trúc Thư Mục

```
vietmap_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/                        # Core utilities
│   │   ├── logger.dart              # Logging system
│   │   ├── retry.dart               # Exponential backoff
│   │   ├── grid_index.dart          # Spatial indexing
│   │   ├── speed_smoother.dart      # EMA filter
│   │   ├── location/
│   │   │   └── location_controller.dart  # Unified location stream
│   │   └── engine/
│   │       └── engine_config.dart   # Engine configuration
│   ├── data/                        # Data layer
│   │   ├── repositories/            # Repository pattern
│   │   │   ├── base_repository.dart
│   │   │   ├── camera_repository.dart
│   │   │   ├── railway_repository.dart
│   │   │   ├── danger_zone_repository.dart
│   │   │   └── speed_limit_repository.dart
│   │   ├── cameras/                 # Camera models
│   │   ├── cooldown_db.dart         # SQLite cooldown DB
│   │   └── models/                  # Data models
│   ├── features/                    # Feature modules
│   │   ├── map/                     # Map screen
│   │   │   ├── map_screen.dart
│   │   │   ├── map_screen_controller.dart
│   │   │   └── map_service.dart
│   │   ├── warning/                 # Warning system
│   │   │   ├── warning_engine.dart
│   │   │   ├── warning_manager.dart
│   │   │   └── warning_model.dart
│   │   ├── navigation/              # Navigation
│   │   │   ├── route_engine.dart
│   │   │   ├── navigation_engine.dart
│   │   │   └── voice/
│   │   ├── simulation/              # Simulation mode
│   │   │   ├── location_simulator.dart
│   │   │   ├── simulation_screen.dart
│   │   │   └── simulation_controller.dart
│   │   ├── debug/                   # Debug tools
│   │   │   ├── debug_screen.dart
│   │   │   ├── fake_location_service.dart
│   │   │   └── route_simulator_service.dart
│   │   └── settings/                # Settings
│   ├── ui/                          # UI components
│   │   ├── hud/                     # HUD widgets
│   │   │   ├── speedometer.dart
│   │   │   └── speed_limit_sign.dart
│   │   └── widgets/                # Reusable widgets
│   │       └── camera_bottom_sheet.dart
│   └── tools/                       # Dart scripts
│       ├── osm_importer.dart
│       ├── merge_speed_limit.dart
│       ├── clean_datasets.dart
│       ├── fix_and_minify.dart
│       └── generate_vector_tiles.dart
├── assets/                          # Assets
│   ├── icons/                       # Icons
│   └── data_sources/final/          # Final datasets
│       ├── cameras.min.json
│       ├── railway.min.json
│       ├── danger_zone.min.json
│       └── speed_limit.min.json
└── android/                         # Android native code
    └── app/src/main/                # (Chưa có background service)
```

### Data Flow

```
GPS / Simulation
    ↓
LocationController (unified stream)
    ↓
    ├──→ MapScreen (UI update)
    ├──→ WarningEngine (check warnings)
    └──→ NavigationEngine (route progress)

WarningEngine
    ↓
    ├──→ CameraRepository.queryNearby()
    ├──→ RailwayRepository.queryNearby()
    ├──→ DangerZoneRepository.queryNearby()
    └──→ SpeedLimitRepository.queryNearby()
    ↓
WarningManager.emit()
    ↓
    ├──→ TTS (speak)
    ├──→ Vibration (vibrate)
    └──→ UI (update counters)
```

### Key Components

1. **LocationController**: Single source of truth cho location updates
   - Real GPS hoặc simulated
   - BehaviorSubject stream
   - Auto-disable real GPS trong simulation mode

2. **WarningEngine**: Core logic cho cảnh báo
   - Listen từ LocationController
   - Query nearby features từ repositories
   - Check cooldown
   - Emit warnings

3. **BaseRepository**: Base class cho tất cả repositories
   - Spatial indexing (GridIndex)
   - Grid cache
   - Query nearby items

4. **GridIndex**: Spatial indexing system
   - Cell size: 0.01° (~1.1km)
   - Query neighborhood: current + 8 adjacent cells
   - O(1) lookup thay vì O(n)

---

## 🛠️ Công Nghệ Sử Dụng

### Flutter App
- **Framework:** Flutter 3.32.4+ (Dart 3.8.1+)
- **Map:** 
  - `maplibre_gl` 0.16.0 (vector tiles)
  - `flutter_map` 8.2.2 (OSM tiles - legacy)
- **GPS:** `geolocator` 14.0.2
- **TTS:** `flutter_tts` 4.2.3
- **Vibration:** `vibration_standard` 1.0.1
- **State Management:** `flutter_riverpod` 2.5.1
- **Reactive Streams:** `rxdart` 0.27.7
- **Database:** `sqflite` (SQLite cache)
- **HTTP:** `http` package
- **Geometry:** `latlong2` 0.9.1

### Backend/API
- **OSRM:** Routing API (public server hoặc self-hosted)
- **Overpass API:** OSM data query (5 mirrors)

### Data Pipeline
- **Tippecanoe:** Convert GeoJSON → MBTiles
- **Dart Scripts:** Data processing tools

---

## 📊 Tổng Kết

### Đã Hoàn Thành: ~85%

**Core Features:**
- ✅ Map display với GPS tracking
- ✅ Camera/Railway/Danger/Speed limit detection
- ✅ Warning system với TTS và vibration
- ✅ Navigation với voice guidance
- ✅ Simulation mode cho testing
- ✅ Debug tools
- ✅ Data pipeline từ OSM

**Architecture:**
- ✅ Repository pattern
- ✅ Spatial indexing
- ✅ Unified location stream
- ✅ Error handling và logging
- ✅ Fallback chain

### Chưa Hoàn Thành: ~15%

**Critical (Cần cho production):**
- ❌ Android background service
- ❌ Comprehensive testing
- ❌ Performance optimization

**Nice to Have:**
- ❌ Advanced features (dark mode, recording, etc.)
- ❌ UI enhancements (layer toggle, etc.)

### Ưu Tiên Tiếp Theo

1. **Android Background Service** (Phase 9)
   - Cần cho production
   - Cho phép cảnh báo khi màn hình tắt

2. **Testing & Stabilization** (Phase 10)
   - Stress tests
   - Integration tests
   - Performance tests

3. **UI Enhancements** (Phase 4.4 - tiếp tục)
   - Layer toggle
   - Feature info bottom sheets
   - Loading indicators

---

## 📝 Ghi Chú

- **Dữ liệu nguồn:** Từ OSM (Overpass API) → JSON → MBTiles
- **Cooldown system:** Tránh spam warnings (40-60s tùy loại)
- **Speed smoothing:** EMA filter để loại bỏ GPS noise
- **Spatial indexing:** GridIndex giảm query time từ O(n) xuống ~O(1)
- **Simulation mode:** Developer tool để test không cần di chuyển thật

---

**Tạo bởi:** Cursor AI Agent  
**Ngày:** 2025-01-XX  
**Version:** 1.0.0

