# Phase 4 PR Checklist

## Summary of Changes

Phase 4 implementation includes:
- **4.1**: Map integration with vector tiles (MBTiles support)
- **4.2**: Data repositories with spatial indexing
- **4.3**: Warning engine with real-time alerts
- **4.4**: UI widgets for warnings
- **4.5**: Background service integration (partial)
- **4.6**: CI, lint, tests

## Files Touched

### New Files
- `lib/config/map_layers_loader.dart`
- `lib/features/map/map_service.dart`
- `lib/data/repositories/base_repository.dart`
- `lib/data/repositories/danger_zone_repository.dart`
- `lib/data/repositories/railway_repository.dart`
- `lib/data/repositories/camera_repository.dart`
- `lib/data/repositories/speed_limit_repository.dart`
- `lib/features/warning/warning_model.dart`
- `lib/features/warning/warning_manager.dart`
- `lib/features/warning/warning_engine.dart`
- `lib/data/cooldown_db.dart`
- `lib/ui/widgets/warning_banner.dart`
- `tools/mbtiles_tile_server.dart`
- `test/data/repositories/repository_test.dart`
- `test/features/warning/warning_engine_test.dart`

### Modified Files
- `pubspec.yaml` (dependencies + assets)
- `lib/features/map/map_screen.dart`
- `lib/core/grid_index.dart` (added clear() method)

## How to Test

### Manual Steps

1. **Run app:**
   ```bash
   cd vietmap_app
   flutter pub get
   flutter run
   ```

2. **Test Map Integration:**
   - Open MapScreen
   - Verify map loads
   - Check if vector tiles indicator shows (if MBTiles available)

3. **Test Repositories:**
   ```bash
   flutter test test/data/repositories/repository_test.dart
   ```

4. **Test Warning Engine:**
   ```bash
   flutter test test/features/warning/warning_engine_test.dart
   ```

5. **Test with GPS:**
   - Enable GPS on device/emulator
   - Move to location with cameras/railway/danger zones
   - Verify warnings appear

### Automated Tests

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/data/repositories/
flutter test test/features/warning/

# Analyze code
flutter analyze

# Format check
dart format --set-exit-if-changed .
```

## Artifacts

- `.cursor/artifacts/phase4/map_integration.log`
- `.cursor/artifacts/phase4/phase4_implementation.log`

## CI Steps

1. ✅ `flutter analyze` - No issues
2. ✅ `dart format --set-exit-if-changed .` - Code formatted
3. ✅ `flutter test` - All tests pass

## Reviewer Tags

- @frontend-lead - UI integration, warning widgets
- @android-lead - Background service, MethodChannel integration

## Known Issues

- Phase 4.5 (Background Integration) is partial - android_service_bridge.dart pending
- MBTiles tile server needs testing with actual MBTiles file
- Warning engine needs integration into MapScreen

## Next Steps After Merge

1. Complete android_service_bridge.dart
2. Integrate WarningEngine into MapScreen
3. Add warning_list.dart widget
4. Test with real GPS data

