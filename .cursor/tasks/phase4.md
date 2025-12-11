# Phase 4 — Cảnh báo camera bằng âm thanh



## 🎯 Mục tiêu

- Dùng flutter_tts để đọc cảnh báo

- Kiểm tra khoảng cách user → camera

- Nếu user < 150m → cảnh báo 1 lần



## Công việc

1. Tính distance giữa user & camera bằng latlong2

2. Lưu cameraAlerted = {}

3. Nếu chưa cảnh báo:

   tts.speak("Sắp đến camera phạt nguội phía trước")

4. Chỉ cảnh báo lại khi user đi xa > 300m



## ✔ Kết quả

- App cảnh báo giọng nói khi lại gần camera

- Không spam cảnh báo



## ▶ Next

Phase5

