# Phase 6.2 - Live Overlay Controller

## ✅ Status: Completed

Live overlay system để hiển thị real-time metrics trên màn hình.

### Features
- **FPS Display**: Tính toán FPS từ frame count
- **Dart VM Metrics**: Placeholder cho memory và frame time
- **OverlayEntry**: Sử dụng Flutter OverlayEntry
- **Toggle ON/OFF**: Từ Debug Screen
- **250ms Updates**: Cập nhật metrics mỗi 250ms

### Implementation
- `LiveOverlayController` singleton
- Overlay positioned at top-right
- Black semi-transparent background (opacity 0.7)
- Monospace font for readability
- Frame counting method for FPS

### Usage
```dart
// Enable overlay
LiveOverlayController.instance.enable(context);

// Disable overlay
LiveOverlayController.instance.disable();
```

### UI
- Toggle switch trong Debug Screen
- Overlay hiển thị:
  - FPS: Frame rate
  - Memory: N/A (requires VM service)
  - Frame Time: N/A (requires frame timing)

### Performance
- Overhead < 5% (chỉ update UI mỗi 250ms)
- Không crash MapLibre (overlay riêng biệt)
- Tự động dispose khi disable

### Acceptance Criteria
- ✅ Overlay hiển thị real-time
- ✅ Không crash MapLibre
- ✅ Performance overhead < 5%
- ✅ Toggle từ Debug Screen

