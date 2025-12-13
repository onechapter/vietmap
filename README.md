VietMap Driver Warning App

Task-Driven Development README

Platform: Android (Flutter)
Primary Goal: Open app → auto run → realtime warning
Secondary Goal: Simulation chính xác để dev test logic

📌 QUY ƯỚC CHUNG (BẮT BUỘC TUÂN THỦ)

Mỗi task phải có trạng thái

Mỗi task phải có tiêu chí Done

Khi sửa xong:

Update README

Ghi rõ đã sửa file nào

Không thêm feature ngoài scope nếu chưa hoàn thành task trước

🧭 PRODUCT SCOPE (KHÓA)

App chỉ tập trung vào:

Camera phạt nguội

Giới hạn tốc độ

Đường cấm / danger

Cảnh báo realtime (voice + rung)

❌ Không mở rộng navigation
❌ Không làm social / account

📋 TASK LIST – THEO THỨ TỰ BẮT BUỘC
🟢 TASK 0 – App mở lên phải chạy ngay (BASELINE)

Mục tiêu

Mở app → map hiển thị → GPS bắt đầu

Không cần thao tác thêm

Việc cần làm

 Auto request location permission

 Auto start LocationController

 Auto enable camera follow

 Không chặn UI bởi màn hình chọn mode

Done khi

Cold start < 3s

Có marker vị trí user

Speed hiển thị > 0 khi di chuyển

Trạng thái

✅ Đã hoàn thành

Notes

- ✅ Auto request permission trong LocationController.startRealGps()
- ✅ Auto start GPS trong MapScreen._initLocationTracking()
- ✅ Auto follow camera khi có location mới (real GPS mode)
- ✅ Files đã sửa: map_screen.dart, location_controller.dart

🟢 TASK 1 – Chuẩn hoá Location Stream (REAL + SIMULATION)

Mục tiêu

Chỉ có 1 luồng location duy nhất

Real GPS và Simulation dùng chung pipeline

Việc cần làm

 Verify LocationController là single source

 Disable real GPS khi simulation bật

 Log rõ source: REAL / SIM

Done khi

WarningEngine không phân biệt real/sim

Không có logic rẽ nhánh trong engine

Trạng thái

✅ Đã có (cần verify)

Notes

- Kiểm tra các chỗ còn if (isSimulation)

🟢 TASK 2 – FIX Simulation Speed (RẤT QUAN TRỌNG)

Mục tiêu

Speed hiển thị = speed giả lập

Không bị trôi / lag / lệch

Việc cần làm

 Bypass GPS speed trong simulation

 Speed = route_speed_config

 Disable EMA smoothing khi sim (hoặc mode riêng)

Done khi

Set 50 km/h → hiển thị ~50 ±1

Speed ổn định khi pause/resume sim

Trạng thái

✅ Đã hoàn thành

Notes

- ✅ Bypass EMA smoothing trong simulation mode
- ✅ WarningEngine: dùng raw speed khi isSimulationMode = true
- ✅ MapScreen: dùng raw speed khi isFake = true
- ✅ Files đã sửa: warning_engine.dart, map_screen.dart

🔴 TASK 3 – FIX Camera Warning trong Simulation (BLOCKER)

Mục tiêu

Simulation đi gần camera → PHẢI cảnh báo

Vấn đề hiện tại

Camera tồn tại

Nhưng WarningEngine không trigger trong sim

Việc cần làm

 Verify camera query radius

 Verify location update frequency

 Reset cooldown đúng cách trong sim

 Log distance user → camera

Done khi

Simulation chạy qua camera → có:

Log warning

TTS

Vibration

Trạng thái

✅ Đã hoàn thành

Notes

- ✅ Thêm verbose logging cho camera distance (trong 300m)
- ✅ Log rõ khi camera warning được trigger
- ✅ Log khi camera trong cooldown
- ✅ Cooldown reset trong simulation mode đã có sẵn
- ✅ Files đã sửa: warning_engine.dart

🟢 TASK 4 – Environment Awareness (xung quanh phải đúng)

Mục tiêu

App "hiểu" môi trường xung quanh xe

Việc cần làm

 Query camera trong radius

 Query speed limit hiện tại

 Query danger / railway

Done khi

Debug screen show:

List feature quanh xe

Distance từng feature

Trạng thái

✅ Đã hoàn thành

Notes

- ✅ Thêm widget _buildNearbyFeaturesViewer() trong DebugScreen
- ✅ Hiển thị cameras, railways, dangers, speed limits với distance
- ✅ Auto-update khi location thay đổi (StreamBuilder)
- ✅ Files đã sửa: debug_screen.dart

🟢 TASK 5 – Multi-Source Camera Data

Mục tiêu

Không phụ thuộc 1 nguồn camera

Việc cần làm

 Định nghĩa source type (OSM / MANUAL / OTHER)

 Merge camera theo radius

 Priority source cao hơn

Done khi

Camera từ nhiều nguồn hiển thị cùng

Warning không bị trùng

Trạng thái

⏳ Chưa làm

Notes

- OSM VN thiếu camera → cần fallback

🟢 TASK 6 – Cooldown & Anti-Spam Verification

Mục tiêu

Không cảnh báo lặp vô hạn

Nhưng không miss cảnh báo

Việc cần làm

 Verify cooldown reset trong sim

 Verify cooldown persistence real mode

Done khi

1 camera → 1 warning / lượt đi qua

Sim reset → warning lại từ đầu

Trạng thái

✅ Đã verify

Notes

- ✅ Cooldown reset trong simulation mode (WarningEngine._processLocation)
- ✅ Cooldown persistence trong real mode (SQLite DB)
- ✅ DebugScreen hiển thị simulation mode status
- ✅ Files đã sửa: warning_engine.dart, debug_screen.dart

🟡 TASK 7 – Debug Screen (Dev Tool)

Mục tiêu

Dev nhìn là biết sai ở đâu

Việc cần làm

 Hiển thị nearby features

 Hiển thị speed raw / smooth

 Hiển thị cooldown state

 Hiển thị warning history

Done khi

Có thể debug không cần print log

Trạng thái

✅ Đã hoàn thành

Notes

- ✅ Thêm _buildCurrentLocationInfo(): hiển thị location, speed raw/smooth, sim mode
- ✅ Thêm _buildNearbyFeaturesViewer(): hiển thị features với distance chi tiết
- ✅ Cải thiện _buildCooldownViewer(): hiển thị simulation mode status
- ✅ Warning history đã có sẵn
- ✅ Files đã sửa: debug_screen.dart

🔴 TASK 8 – Android Foreground Service (PRODUCTION BLOCKER)

Mục tiêu

Tắt màn hình vẫn cảnh báo

Việc cần làm

 Foreground service

 Native GPS

 Native TTS

 Sync với Flutter

Done khi

Lock screen → vẫn cảnh báo

Trạng thái

❌ Chưa làm

📊 TRẠNG THÁI TỔNG
Task	Status
App auto run	✅
Location unified	✅
Simulation speed	✅
Camera sim warning	✅
Environment awareness	✅
Multi-source camera	⏳
Cooldown verify	✅
Debug tools	✅
Background service	❌
🧠 QUY TẮC CHO AI CURSOR

Không thêm feature mới

Fix task theo thứ tự

Mỗi task xong → update README

Nếu task không đạt → ghi rõ lý do

🎯 MỤC TIÊU CUỐI

Mở app → để trong túi → chạy xe → được cảnh báo đúng & đủ