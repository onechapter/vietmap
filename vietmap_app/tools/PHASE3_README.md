# Phase 3 - Vector Tiles Generation

## 📋 Mục tiêu

Chuyển đổi GeoJSON → MBTiles (Vector Tiles) để sử dụng trong MapLibre/Mapbox.

## 🔧 Yêu cầu

### Cài đặt Tippecanoe

**Windows:**
```powershell
# Option 1: Chocolatey
choco install tippecanoe

# Option 2: Download binary
# Tải từ: https://github.com/felt/tippecanoe/releases
# Giải nén và thêm vào PATH
```

**macOS:**
```bash
brew install tippecanoe
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install tippecanoe

# Hoặc build from source
git clone https://github.com/felt/tippecanoe.git
cd tippecanoe
make -j
sudo make install
```

## 🚀 Cách chạy

### Option 1: Dart Script (Recommended)
```bash
cd vietmap_app
dart run tools/generate_vector_tiles.dart
```

### Option 2: PowerShell Script
```powershell
cd vietmap_app
.\tools\generate_vector_tiles.ps1
```

### Option 3: Bash Script (Linux/macOS)
```bash
cd vietmap_app
chmod +x tools/generate_vector_tiles.sh
./tools/generate_vector_tiles.sh
```

## 📁 Output Files

Sau khi chạy, bạn sẽ có:

```
vietmap_app/
├── vietmap.mbtiles          # Unified vector tiles file
├── tiles/
│   ├── danger_zone.mbtiles   # Individual layer
│   ├── railway.mbtiles      # Individual layer
│   ├── cameras.mbtiles      # Individual layer
│   └── speed_limit.mbtiles  # Individual layer
└── data_sources/final/
    └── tile_metadata.json    # Metadata file
```

## 📊 Tippecanoe Options Explained

### Danger Zone (Polygon - Heavy)
- `--no-feature-limit`: Không giới hạn số features
- `--no-tile-size-limit`: Không giới hạn kích thước tile
- `--drop-densest-as-needed`: Bỏ các features dày đặc nhất khi cần
- `--extend-zooms-if-still-dropping`: Mở rộng zoom nếu vẫn còn bỏ features
- `--coalesce-smallest-as-needed`: Gộp các features nhỏ nhất khi cần

### Railway/Cameras/Speed Limit (Light)
- Chỉ dùng `--force` để overwrite file cũ

## 🔍 Kiểm tra Output

```bash
# Kiểm tra file size
ls -lh vietmap.mbtiles

# Kiểm tra metadata (nếu có sqlite3)
sqlite3 vietmap.mbtiles "SELECT * FROM metadata;"
```

## 📱 Sử dụng trong App

### MapLibre GL (Flutter)
```dart
import 'package:maplibre_gl/maplibre_gl.dart';

// Load từ local file
await mapController.addSource(
  'vietmap',
  VectorSourceProperties(
    url: 'asset://vietmap.mbtiles',
  ),
);
```

### MapLibre Native (Android/iOS)
```kotlin
// Android
val source = VectorSource("vietmap", "asset://vietmap.mbtiles")
mapView.getMapAsync { map ->
    map.style.addSource(source)
}
```

## ⚠️ Troubleshooting

### Error: tippecanoe not found
- Đảm bảo tippecanoe đã được cài đặt và có trong PATH
- Kiểm tra: `tippecanoe --version`

### Error: tile-join not found
- tile-join đi kèm với tippecanoe
- Nếu thiếu, cài lại tippecanoe

### File quá lớn
- Danger zone có thể tạo file rất lớn
- Có thể cần tăng `--drop-densest-as-needed` hoặc simplify polygon trước

### Empty layers
- Cameras và speed_limit có thể rỗng (0 items)
- Vẫn tạo layer để app không bị lỗi khi load

## 📝 Metadata

File `tile_metadata.json` chứa:
- Version, zoom levels
- Bounding box
- Layer names
- Counts per layer
- Generated date

## 🎨 Layer Styling

Xem `config/map_layers.json` để cấu hình màu sắc và style cho từng layer.

