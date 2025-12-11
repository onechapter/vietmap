# Phase 4.2 - Warning Engine với Vector Tiles

## 📋 Mục tiêu

Xây dựng engine cảnh báo dựa trên vector tiles data, thay vì chỉ dùng JSON files. Engine query features từ tiles dựa trên vị trí GPS hiện tại.

## 🎯 Description

- Query features từ vector tiles theo bounding box hiện tại
- Tính khoảng cách từ user position đến các features (danger zones, railway, cameras)
- Trigger warnings khi user vào vùng nguy hiểm hoặc gần camera/railway
- Tích hợp với TTS và vibration system hiện có
- Anti-spam logic (cooldown per feature)

## 🔧 Commands

```bash
# 1. Test warning engine
cd vietmap_app
dart run tools/test_warning_engine.dart --lat 10.762622 --lng 106.660172

# 2. Run app với GPS simulation
flutter run --dart-define=GPS_SIMULATE=true

# 3. Check logs
cat .cursor/artifacts/phase4/warning_engine.log
```

## 📁 Files to Create/Modify

### New Files
- `lib/features/warnings/vector_tile_query_service.dart` - Query features từ tiles
- `lib/features/warnings/warning_engine.dart` - Main engine logic
- `lib/features/warnings/proximity_checker.dart` - Check khoảng cách và trigger warnings
- `lib/features/warnings/warning_cooldown_manager.dart` - Quản lý cooldown để tránh spam

### Modified Files
- `lib/features/map/map_screen.dart` - Tích hợp warning engine
- `lib/core/logger.dart` - Thêm warning-specific logs

## ✅ Expected Outputs

1. **Warning engine chạy mỗi GPS update** (mỗi 1-2 giây)
2. **Query features** từ tiles trong bán kính 500m
3. **Warnings được trigger** khi:
   - User vào danger zone polygon
   - User gần railway crossing < 300m
   - User gần camera < 150m
   - User vượt tốc độ (so với speed_limit)
4. **TTS phát cảnh báo** với message phù hợp
5. **Cooldown hoạt động** - không spam cùng feature trong 40-60s
6. **Logs**: `.cursor/artifacts/phase4/warning_engine.log`

## 📊 Acceptance Criteria

- [ ] `VectorTileQueryService` query được features từ tiles
- [ ] `WarningEngine` check được proximity cho tất cả 4 loại features
- [ ] Point-in-polygon check hoạt động cho danger zones
- [ ] Haversine distance tính đúng cho railway/cameras
- [ ] TTS warnings được trigger đúng thời điểm
- [ ] Cooldown manager ngăn spam warnings
- [ ] Logs ghi lại mỗi warning event
- [ ] Performance: query < 100ms cho bán kính 500m

## 🧪 Testing

```bash
# Unit tests
flutter test test/features/warnings/

# Integration test với mock GPS
flutter test test/integration/warning_engine_test.dart

# Manual test với real GPS
flutter run
# Di chuyển đến gần camera/railway/danger zone
# Kiểm tra warnings được phát
```

## 📝 Notes

- Vector tiles query nhanh hơn JSON parsing
- Có thể cache query results trong memory
- Cần handle trường hợp tiles chưa load xong
- Warnings có thể ưu tiên theo mức độ nguy hiểm

## 🔄 Integration với Existing Code

- Sử dụng `SpeedSmoother` hiện có
- Tích hợp với `flutter_tts` và `vibration` packages
- Dùng `GridIndex` nếu cần optimize thêm
- Kế thừa `appLog` logging system

