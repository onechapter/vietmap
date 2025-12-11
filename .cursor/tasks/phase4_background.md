# Phase 4.5 - Background Service Integration

## 📋 Mục tiêu

Tích hợp vector tiles warning engine vào Android background service, đảm bảo warnings hoạt động khi app ở background hoặc màn hình tắt.

## 🎯 Description

- Background service query vector tiles data (hoặc cache)
- GPS location updates trigger warning checks
- TTS và vibration hoạt động trong background
- Lightweight tile query (chỉ query cần thiết)
- Battery optimization (throttle queries khi không di chuyển)

## 🔧 Commands

```bash
# 1. Build Android release
cd vietmap_app
flutter build apk --release

# 2. Install và test background
adb install build/app/outputs/flutter-apk/app-release.apk
# Tắt màn hình, di chuyển → kiểm tra warnings

# 3. Check logs
adb logcat | grep "VietMap"
cat .cursor/artifacts/phase4/background.log
```

## 📁 Files to Create/Modify

### New Files
- `android/app/src/main/kotlin/.../LocationService.kt` - Background service (nếu chưa có)
- `lib/services/background_warning_service.dart` - Flutter service wrapper
- `lib/services/tile_cache_service.dart` - Cache tiles data cho background
- `lib/platform/background_channel.dart` - MethodChannel cho background communication

### Modified Files
- `lib/features/warnings/warning_engine.dart` - Support background mode
- `android/app/src/main/AndroidManifest.xml` - Permissions và service declaration

## ✅ Expected Outputs

1. **Background service chạy** khi app ở background
2. **GPS updates** trigger warning checks
3. **Warnings được phát** (TTS/vibration) trong background
4. **Tile data được cache** để query nhanh
5. **Battery efficient**: Throttle queries khi không di chuyển
6. **Logs**: `.cursor/artifacts/phase4/background.log`

## 📊 Acceptance Criteria

- [ ] Background service được khởi động khi app vào background
- [ ] Service nhận được GPS location updates
- [ ] Warning engine chạy được trong background context
- [ ] TTS hoạt động trong background (Android foreground service)
- [ ] Vibration hoạt động trong background
- [ ] Tile data được cache để query nhanh
- [ ] Battery usage hợp lý (< 5% mỗi giờ khi di chuyển)
- [ ] Logs ghi lại mọi background warnings

## 🧪 Testing

```bash
# Test background service
flutter test test/services/background_warning_service_test.dart

# Manual test
flutter run --release
# 1. Mở app, bật GPS
# 2. Đưa app vào background (home button)
# 3. Di chuyển → kiểm tra warnings
# 4. Tắt màn hình → kiểm tra warnings vẫn hoạt động

# Battery test
# Chạy app 1 giờ, kiểm tra battery usage
```

## 📝 Notes

- Background service cần foreground notification (Android requirement)
- Tile cache có thể lưu vào SQLite hoặc memory
- Query tiles trong background: chỉ query bán kính nhỏ (200m) để tiết kiệm battery
- Có thể disable background warnings trong settings

## 🔄 Integration với Phase 3

- Sử dụng `VectorTileRepository` để query tiles
- Cache metadata và features trong `TileCacheService`
- Background service chỉ query khi cần (user di chuyển)

## ⚠️ Android Requirements

- Foreground service với notification
- Location permission (foreground + background)
- Battery optimization exemption (nếu cần)
- Wake lock (nếu cần warnings khi screen off)

## 📱 iOS Considerations

- iOS không hỗ trợ background location tốt như Android
- Có thể chỉ support background warnings trên Android
- iOS: warnings chỉ hoạt động khi app foreground

