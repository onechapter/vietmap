# Manual Test Cases

## Test Case 1: WarningEngine - Camera Detection
**Steps:**
1. Mở app
2. Di chuyển đến gần camera (trong 150m)
3. Kiểm tra TTS announcement
4. Kiểm tra vibration
5. Kiểm tra warning banner

**Expected:**
- TTS: "Sắp đến camera phạt nguội phía trước"
- Vibration trigger
- Warning banner hiển thị

## Test Case 2: Navigation - Route Calculation
**Steps:**
1. Mở Navigation Screen
2. Nhập điểm đến
3. Chờ route calculation
4. Kiểm tra route line trên map

**Expected:**
- Route tính toán thành công
- Route line hiển thị đúng
- Steps hiển thị đầy đủ

## Test Case 3: Navigation - Voice Guidance
**Steps:**
1. Bắt đầu navigation
2. Di chuyển theo route
3. Đến gần maneuver (500m, 200m, 50m)
4. Kiểm tra TTS announcements

**Expected:**
- Announcements đúng thời điểm
- Không bị lặp
- Queue không bị nghẽn

## Test Case 4: Reroute - Off-Route Detection
**Steps:**
1. Bắt đầu navigation
2. Đi lệch khỏi route >30m
3. Kiểm tra reroute trigger
4. Kiểm tra route mới

**Expected:**
- Reroute trigger sau 15s cooldown
- Route mới hiển thị
- Smooth transition

## Test Case 5: Offline Mode
**Steps:**
1. Tắt mạng hoàn toàn
2. Bắt đầu navigation với cached route
3. Kiểm tra offline indicator
4. Test offline reroute

**Expected:**
- Offline indicator hiển thị
- Cached route load đúng
- Offline reroute hoạt động

## Test Case 6: Background Mode
**Steps:**
1. Bắt đầu navigation
2. Tắt màn hình
3. Chờ 30 phút
4. Mở lại app

**Expected:**
- Warnings vẫn hoạt động
- TTS vẫn announce
- Navigation vẫn chạy

## Test Case 7: Memory Leak Test
**Steps:**
1. Bắt đầu navigation
2. Chạy 20 phút
3. Kiểm tra memory usage
4. Stop navigation
5. Kiểm tra memory release

**Expected:**
- Memory stable trong 20 phút
- Memory giảm sau khi stop
- Không có leak

## Test Case 8: Start/Stop Stress Test
**Steps:**
1. Start navigation
2. Stop navigation
3. Lặp lại 10 lần
4. Kiểm tra memory và crash

**Expected:**
- Không crash
- Memory không tăng
- Resources được giải phóng

## Test Case 9: GPS Signal Loss
**Steps:**
1. Bắt đầu navigation
2. Vào khu vực mất GPS (tunnel, building)
3. Chờ GPS phục hồi
4. Kiểm tra navigation resume

**Expected:**
- App không crash
- Navigation resume khi GPS phục hồi
- Retry logic hoạt động

## Test Case 10: App Lifecycle
**Steps:**
1. Bắt đầu navigation
2. Minimize app
3. Chờ 5 phút
4. Return to app
5. Kiểm tra state

**Expected:**
- Navigation resume đúng
- State được preserve
- Không crash

