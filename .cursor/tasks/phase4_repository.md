# Phase 4.3 - Repository Pattern cho Vector Tiles

## 📋 Mục tiêu

Refactor code để sử dụng Repository pattern cho vector tiles data, tách biệt data layer và business logic. Hỗ trợ cả MBTiles và JSON fallback.

## 🎯 Description

- Tạo `VectorTileRepository` để abstract việc load tiles
- Hỗ trợ 2 data sources: MBTiles (ưu tiên) và JSON fallback
- Cache metadata và features trong memory
- Provide clean API cho warning engine và map screen
- Error handling và fallback logic

## 🔧 Commands

```bash
# 1. Run repository tests
cd vietmap_app
flutter test test/data/repositories/vector_tile_repository_test.dart

# 2. Check repository initialization
dart run tools/test_repository.dart

# 3. Logs
cat .cursor/artifacts/phase4/repository.log
```

## 📁 Files to Create/Modify

### New Files
- `lib/data/repositories/vector_tile_repository.dart` - Main repository interface
- `lib/data/repositories/mbtiles_repository.dart` - MBTiles implementation
- `lib/data/repositories/json_fallback_repository.dart` - JSON fallback implementation
- `lib/data/models/vector_feature.dart` - Model cho features từ tiles
- `lib/data/models/tile_metadata_model.dart` - Model cho metadata

### Modified Files
- `lib/features/map/map_screen.dart` - Sử dụng repository thay vì direct load
- `lib/features/warnings/warning_engine.dart` - Sử dụng repository để query

## ✅ Expected Outputs

1. **Repository interface** với methods:
   - `loadMetadata()` - Load tile metadata
   - `queryFeatures(bbox, layers)` - Query features trong bbox
   - `getFeatureById(id, layer)` - Get feature by ID
   - `isAvailable()` - Check data source available
2. **MBTiles implementation** load từ `vietmap.mbtiles`
3. **JSON fallback** load từ `.min.json` files nếu MBTiles không có
4. **Caching** metadata và recent queries
5. **Logs**: `.cursor/artifacts/phase4/repository.log`

## 📊 Acceptance Criteria

- [ ] `VectorTileRepository` interface được định nghĩa rõ ràng
- [ ] `MBTilesRepository` load được từ MBTiles file
- [ ] `JSONFallbackRepository` load được từ JSON files
- [ ] Repository tự động fallback nếu MBTiles không có
- [ ] Metadata được cache sau lần load đầu
- [ ] Query results có thể cache trong memory
- [ ] Error handling đầy đủ (file not found, parse error, etc.)
- [ ] Logs ghi lại mọi repository operations

## 🧪 Testing

```bash
# Unit tests
flutter test test/data/repositories/

# Test với MBTiles
flutter test test/data/repositories/mbtiles_repository_test.dart

# Test với JSON fallback
flutter test test/data/repositories/json_fallback_repository_test.dart

# Integration test
flutter test test/integration/repository_integration_test.dart
```

## 📝 Notes

- Repository pattern giúp dễ test và maintain
- Có thể thêm data source khác (API, SQLite) sau này
- Cache strategy: metadata cache forever, features cache 5 phút
- Repository singleton hoặc dependency injection

## 🔄 Architecture

```
MapScreen / WarningEngine
    ↓
VectorTileRepository (interface)
    ↓
MBTilesRepository | JSONFallbackRepository
    ↓
vietmap.mbtiles | *.min.json files
```

