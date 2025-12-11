# Pre-Release QA Checklist

## Functional Tests

### WarningEngine
- [ ] Test thực tế với GPS thật
- [ ] Camera warnings trigger đúng khoảng cách
- [ ] Speed limit warnings hoạt động
- [ ] Danger zone warnings hoạt động
- [ ] Railway warnings hoạt động
- [ ] TTS announcements rõ ràng
- [ ] Vibration hoạt động

### Navigation
- [ ] Route calculation thành công
- [ ] Route hiển thị đúng trên map
- [ ] Maneuver banner update đúng
- [ ] Voice guidance announce đúng thời điểm
- [ ] Reroute khi off-route
- [ ] Offline mode hoạt động

### Background Mode
- [ ] Background service chạy ổn định 30 phút
- [ ] Warnings vẫn hoạt động khi màn hình tắt
- [ ] TTS vẫn hoạt động trong background
- [ ] Battery usage hợp lý

### Start/Stop
- [ ] Navigation start/stop 10 lần liên tục không crash
- [ ] Memory không tăng sau mỗi lần start/stop
- [ ] Resources được giải phóng đúng

## Performance Tests

### Memory
- [ ] Memory stable trong 20 phút navigation
- [ ] Không có memory leak trong:
  - RouteEngine listeners
  - RerouteEngine timers
  - NavigationScreen controllers
  - WarningEngine streams

### CPU
- [ ] CPU < 35% average
- [ ] Không có CPU spike > 70% kéo dài >3s
- [ ] Background CPU < 10%

### Frame Rate
- [ ] Map FPS > 45 ổn định
- [ ] UI không bị lag khi navigation
- [ ] Smooth route transitions

## Edge Cases

### Offline
- [ ] Offline mode hoạt động khi tắt mạng
- [ ] Reroute offline hoạt động
- [ ] Cached routes load đúng

### GPS
- [ ] GPS mất tín hiệu → phục hồi
- [ ] GPS accuracy thấp → vẫn hoạt động
- [ ] GPS timeout → retry logic

### App Lifecycle
- [ ] App minimize → return (resume đúng)
- [ ] App background → foreground
- [ ] Phone call → app resume
- [ ] Low memory → app không crash

### Network
- [ ] API timeout → fallback
- [ ] Network error → retry
- [ ] Slow network → không hang

## Device Matrix

### Android Versions
- [ ] Android 8.0 (API 26)
- [ ] Android 10 (API 29)
- [ ] Android 12 (API 31)
- [ ] Android 14 (API 34)

### Device Types
- [ ] Snapdragon devices
- [ ] MediaTek devices
- [ ] Low-end devices (2GB RAM)
- [ ] High-end devices (8GB+ RAM)

## Acceptance Criteria

- [ ] 95% test cases PASSED
- [ ] Không có ANR (Application Not Responding)
- [ ] Không có crash
- [ ] Navigation liên tục >20 phút không drop frames
- [ ] Memory stable
- [ ] Battery usage hợp lý

