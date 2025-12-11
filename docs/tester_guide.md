# Tester Guide

## Cách bật Debug Overlay

1. Mở app
2. Vào Debug Screen (từ menu hoặc settings)
3. Tìm section "Live Overlay"
4. Toggle switch "Enable Live Overlay"
5. Overlay sẽ hiển thị ở góc trên bên phải với:
   - FPS
   - Memory usage
   - Frame time

## Cách bật Simulator Mode

1. Mở Debug Screen
2. Tìm section "Route Simulator"
3. Load một route (hoặc dùng test route)
4. Toggle "Start Simulation"
5. Điều chỉnh speed bằng slider
6. App sẽ simulate navigation theo route

## Cách lấy Logs

### Method 1: Debug Screen
1. Mở Debug Screen
2. Scroll xuống "Upload Logs"
3. Click "Upload Logs"
4. Xem danh sách log files
5. Click "Upload" trên file muốn gửi
6. Copy ID được trả về

### Method 2: Manual
1. Vào Android Settings
2. Apps > VietMap
3. Storage > Clear Data (nếu cần)
4. Reproduce issue
5. Vào Debug Screen > Upload Logs
6. Gửi log file cho dev

## Log Types

- **error_*.json**: Error logs
- **perf_*.json**: Performance logs
- **telemetry_*.json**: Telemetry logs

## Common Issues

### App crash
1. Lấy crash log từ Upload Logs
2. Ghi lại steps trước khi crash
3. Gửi cho dev team

### Navigation không hoạt động
1. Kiểm tra GPS signal
2. Kiểm tra network connection
3. Thử offline mode
4. Gửi logs nếu vẫn lỗi

### TTS không hoạt động
1. Kiểm tra volume
2. Kiểm tra TTS settings
3. Test với different languages
4. Gửi logs

## Performance Testing

1. Bật Debug Overlay
2. Monitor FPS (should be > 45)
3. Monitor memory (should be stable)
4. Test trong 20 phút
5. Report nếu có spike hoặc leak

## Beta Testing Checklist

- [ ] Navigation hoạt động
- [ ] Warnings trigger đúng
- [ ] Voice guidance rõ ràng
- [ ] Offline mode hoạt động
- [ ] Background mode ổn định
- [ ] Không có crash
- [ ] Performance tốt

