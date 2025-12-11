import 'dart:io';

/// Script to shrink and optimize assets
void main(List<String> args) {
  print('=== Asset Shrinker ===\n');

  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('Assets directory not found');
    return;
  }

  int totalSize = 0;
  int removedSize = 0;
  int filesRemoved = 0;

  // Process images
  _processDirectory(assetsDir, (file) {
    if (file.path.endsWith('.png') || file.path.endsWith('.jpg') || file.path.endsWith('.jpeg')) {
      final size = file.lengthSync();
      totalSize += size;

      // Remove images > 2MB (too large for mobile)
      if (size > 2 * 1024 * 1024) {
        print('Removing large image: ${file.path} (${(size / 1024 / 1024).toStringAsFixed(2)} MB)');
        file.deleteSync();
        removedSize += size;
        filesRemoved++;
      }
    }
  });

  // Process JSON files - remove unused
  final jsonFiles = [
    'assets/cameras/sample.json', // Keep only if needed
  ];

  print('\n=== Summary ===');
  print('Total assets size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('Removed: $filesRemoved files (${(removedSize / 1024 / 1024).toStringAsFixed(2)} MB)');
  print('Remaining: ${((totalSize - removedSize) / 1024 / 1024).toStringAsFixed(2)} MB');
}

void _processDirectory(Directory dir, void Function(File) processor) {
  if (!dir.existsSync()) return;

  for (final entity in dir.listSync()) {
    if (entity is File) {
      processor(entity);
    } else if (entity is Directory) {
      _processDirectory(entity, processor);
    }
  }
}

