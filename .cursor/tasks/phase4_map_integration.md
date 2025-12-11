# Phase 4.1 - Map Integration với Vector Tiles

## 📋 Mục tiêu

Tích hợp `vietmap.mbtiles` vào Flutter app, load và hiển thị các layers (danger_zone, railway, cameras, speed_limit) trên bản đồ MapLibre.

## 🎯 Description

- Cài đặt package `maplibre_gl` hoặc `flutter_map` với vector tiles support
- Load `vietmap.mbtiles` từ assets hoặc local file
- Hiển thị 4 layers: danger_zone (fill), railway (line), cameras (symbol), speed_limit (symbol)
- Áp dụng style từ `config/map_layers.json`
- Tối ưu performance (lazy load, zoom-based visibility)

## 🔧 Commands

```bash
# 1. Add dependencies
cd vietmap_app
flutter pub add maplibre_gl
# hoặc
flutter pub add flutter_map vector_tiles

# 2. Copy vietmap.mbtiles to assets
mkdir -p assets/tiles
cp vietmap.mbtiles assets/tiles/

# 3. Update pubspec.yaml
# Thêm assets/tiles/vietmap.mbtiles vào assets

# 4. Run app
flutter run
```

## 📁 Files to Create/Modify

### New Files
- `lib/features/map/vector_tile_service.dart` - Service để load và quản lý vector tiles
- `lib/features/map/vector_layer_manager.dart` - Manager để add/remove layers
- `lib/data/tiles/tile_metadata_loader.dart` - Load metadata từ tile_metadata.json

### Modified Files
- `lib/features/map/map_screen.dart` - Tích hợp vector tiles thay vì chỉ OSM
- `pubspec.yaml` - Thêm dependencies và assets

## ✅ Expected Outputs

1. **Map hiển thị vector tiles** thay vì chỉ OSM tiles
2. **4 layers visible** trên bản đồ:
   - Danger zones (polygon màu đỏ, opacity 0.6)
   - Railway crossings (điểm màu xanh)
   - Cameras (icon camera, nếu có data)
   - Speed limits (icon speed, nếu có data)
3. **Performance tốt**: Không lag khi zoom/pan
4. **Logs**: `.cursor/artifacts/phase4/map_integration.log`

## 📊 Acceptance Criteria

- [ ] `maplibre_gl` hoặc `flutter_map` với vector tiles được cài đặt
- [ ] `vietmap.mbtiles` được copy vào `assets/tiles/`
- [ ] `pubspec.yaml` khai báo asset
- [ ] `VectorTileService` load được MBTiles
- [ ] `VectorLayerManager` add được 4 layers
- [ ] Layers hiển thị đúng style (màu, opacity, icon)
- [ ] Map không crash khi zoom/pan
- [ ] Log file được tạo với thông tin load tiles

## 🧪 Testing

```bash
# Test load tiles
flutter test test/features/map/vector_tile_service_test.dart

# Test UI
flutter run --profile
# Kiểm tra: zoom in/out, pan, layers visible
```

## 📝 Notes

- Nếu `vietmap.mbtiles` chưa có, fallback về `.min.json` files
- Layers có thể ẩn/hiện theo zoom level để tối ưu performance
- Cần handle error khi file không tồn tại

