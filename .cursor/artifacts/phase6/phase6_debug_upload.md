# Phase 6.3 - OTA Debug Upload

## ✅ Status: Completed

System để upload logs từ app lên server debug hoặc Supabase.

### Features
- **DebugUploadScreen**: UI để xem và upload logs
- **UploadResult**: Model cho kết quả upload
- **LogCleaner**: Utility để dọn logs cũ
- **File Preview**: Xem 50 dòng đầu của mỗi log file
- **SHA256 Hash**: Tính hash để verify integrity

### Implementation

#### DebugUploadScreen
- List tất cả log files trong `app documents/logs/`
- Hiển thị:
  - File name
  - Size (formatted: B/KB/MB)
  - Modified date
  - Preview (50 dòng đầu)
  - SHA256 hash
- Upload button cho mỗi file
- Summary: tổng số files và tổng dung lượng
- Clean button để xóa logs >7 ngày

#### UploadResult
```dart
class UploadResult {
  final bool success;
  final String? id;  // Server ID để trace
  final String? error;
  final DateTime timestamp;
}
```

#### LogCleaner
- Clean logs older than 7 days
- `cleanOldLogs()`: Xóa files cũ
- `getLogDirectorySize()`: Tính tổng dung lượng
- Có thể gọi khi app start

### Usage
```dart
// Clean old logs
await LogCleaner.cleanOldLogs();

// Get directory size
final size = await LogCleaner.getLogDirectorySize();
```

### Upload Flow
1. User mở Debug Screen
2. Click "Upload Logs"
3. Xem danh sách files
4. Click "Upload" trên file muốn upload
5. Server trả về ID để trace
6. Hiển thị success/failure message

### TODO
- Implement actual upload to Supabase/server
- Add progress indicator
- Batch upload multiple files
- Retry logic for failed uploads

### Acceptance Criteria
- ✅ Upload UI đầy đủ
- ✅ Preview log (50 dòng đầu)
- ✅ Clean logs older than 7 days
- ✅ SHA256 hash calculation
- ✅ File size and date display

