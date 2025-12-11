# Phase 2 — Hiển thị bản đồ bằng Flutter Map + OpenStreetMap



## 🎯 Mục tiêu

- Tạo màn hình map

- Show OSM layer

- Lấy vị trí người dùng realtime (GPS)



## Công việc

1. Tạo widget MapScreen

2. Implement FlutterMap:

   ```dart

   TileLayer(

     urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

     userAgentPackageName: "com.example.vietmap_app",

   )




Xin quyền GPS → dùng geolocator



Hiển thị marker vị trí của user



✔ Kết quả



App hiển thị map



Marker user di chuyển theo GPS



▶ Next



Cập nhật workflow → phase3

