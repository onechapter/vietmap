# Phase 4.4 - UI Enhancements với Vector Tiles

## 📋 Mục tiêu

Cải thiện UI để hiển thị thông tin từ vector tiles, thêm interactive features (tap để xem details), và tối ưu performance rendering.

## 🎯 Description

- Hiển thị tooltip/info khi tap vào features trên map
- Bottom sheet hiển thị chi tiết feature (danger zone type, railway info, camera speed limit)
- Layer toggle UI để bật/tắt từng layer
- Loading indicator khi tiles đang load
- Optimize rendering performance (throttle updates, debounce taps)

## 🔧 Commands

```bash
# 1. Run app
cd vietmap_app
flutter run

# 2. Test UI interactions
# Tap vào danger zone → bottom sheet hiện
# Tap vào railway → info popup
# Toggle layers → layers ẩn/hiện

# 3. Check performance
flutter run --profile
# Kiểm tra FPS, memory usage

# 4. Logs
cat .cursor/artifacts/phase4/ui.log
```

## 📁 Files to Create/Modify

### New Files
- `lib/ui/widgets/feature_info_bottom_sheet.dart` - Bottom sheet hiển thị feature details
- `lib/ui/widgets/layer_toggle_panel.dart` - UI để toggle layers
- `lib/ui/widgets/feature_tooltip.dart` - Tooltip khi tap feature
- `lib/ui/widgets/tile_loading_indicator.dart` - Loading indicator

### Modified Files
- `lib/features/map/map_screen.dart` - Thêm tap handlers và UI components
- `lib/ui/widgets/camera_bottom_sheet.dart` - Mở rộng để support tất cả feature types

## ✅ Expected Outputs

1. **Tap vào feature** → Tooltip hoặc bottom sheet hiện
2. **Bottom sheet hiển thị**:
   - Danger zone: type, area (nếu có), description
   - Railway: type, is_crossing, coordinates
   - Camera: name, speed limit, coordinates
   - Speed limit: speed value, coordinates
3. **Layer toggle panel** cho phép bật/tắt từng layer
4. **Loading indicator** khi tiles đang load
5. **Smooth performance**: 60 FPS khi pan/zoom
6. **Logs**: `.cursor/artifacts/phase4/ui.log`

## 📊 Acceptance Criteria

- [ ] Tap vào feature trigger được event
- [ ] Bottom sheet hiển thị đúng thông tin feature
- [ ] Layer toggle hoạt động (ẩn/hiện layers)
- [ ] Loading indicator hiện khi cần
- [ ] Performance: FPS >= 55 khi pan/zoom
- [ ] Memory usage không tăng quá mức khi load nhiều features
- [ ] UI responsive trên các screen sizes
- [ ] Logs ghi lại mọi UI interactions

## 🧪 Testing

```bash
# Widget tests
flutter test test/ui/widgets/

# Integration test
flutter test test/integration/ui_test.dart

# Manual test
flutter run
# Test tap, toggle, scroll bottom sheet
```

## 📝 Notes

- Bottom sheet có thể scroll nếu content dài
- Tooltip tự động dismiss sau 3 giây
- Layer toggle có thể lưu preference vào SharedPreferences
- Performance: debounce tap events (300ms), throttle map updates (100ms)

## 🎨 UI Design

- Bottom sheet: Material Design 3 style
- Tooltip: Rounded corners, shadow, auto-dismiss
- Layer toggle: Checkbox list hoặc switch list
- Loading: CircularProgressIndicator với message

## 🔄 Integration

- Sử dụng `VectorTileRepository` để query feature details
- Tích hợp với existing `CameraBottomSheet`
- Dùng `showModalBottomSheet` từ Flutter Material

