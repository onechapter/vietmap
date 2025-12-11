import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../logging/upload_result.dart';
import '../../logging/log_cleaner.dart';
import '../../core/logger.dart';

class DebugUploadScreen extends StatefulWidget {
  const DebugUploadScreen({super.key});

  @override
  State<DebugUploadScreen> createState() => _DebugUploadScreenState();
}

class _DebugUploadScreenState extends State<DebugUploadScreen> {
  List<LogFileInfo> _logFiles = [];
  bool _loading = true;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _loading = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      final files = logDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log') || f.path.endsWith('.txt'))
          .toList();

      _logFiles = [];
      _totalSize = 0;

      for (final file in files) {
        final stat = file.statSync();
        final size = stat.size;
        final modified = stat.modified;
        final content = await file.readAsString();
        final preview = content.split('\n').take(50).join('\n');
        final hash = sha256.convert(utf8.encode(content)).toString();

        _logFiles.add(LogFileInfo(
          file: file,
          size: size,
          modified: modified,
          preview: preview,
          hash: hash,
        ));

        _totalSize += size;
      }

      // Sort by modified date (newest first)
      _logFiles.sort((a, b) => b.modified.compareTo(a.modified));
    } catch (e) {
      appLog('DebugUploadScreen: Error loading logs: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _uploadLog(LogFileInfo logInfo) async {
    try {
      appLog('DebugUploadScreen: Uploading ${logInfo.file.path}...');

      // TODO: Implement actual upload to server/Supabase
      // For now, simulate upload
      await Future.delayed(const Duration(seconds: 1));

      final result = UploadResult.success('log_${DateTime.now().millisecondsSinceEpoch}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thành công! ID: ${result.id}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      appLog('DebugUploadScreen: Upload success - ${result.id}');
    } catch (e) {
      appLog('DebugUploadScreen: Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanOldLogs() async {
    await LogCleaner.cleanOldLogs();
    await _loadLogFiles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã dọn logs cũ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _cleanOldLogs,
            tooltip: 'Dọn logs cũ (>7 ngày)',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng số file',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${_logFiles.length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tổng dung lượng',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatSize(_totalSize),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Log files list
                Expanded(
                  child: _logFiles.isEmpty
                      ? const Center(child: Text('Không có log files'))
                      : ListView.builder(
                          itemCount: _logFiles.length,
                          itemBuilder: (context, index) {
                            final logInfo = _logFiles[index];
                            return _buildLogFileTile(logInfo);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogFileTile(LogFileInfo logInfo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          path.basename(logInfo.file.path),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatSize(logInfo.size)} • ${_formatDate(logInfo.modified)}',
        ),
        trailing: ElevatedButton(
          onPressed: () => _uploadLog(logInfo),
          child: const Text('Upload'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview (50 dòng đầu):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    logInfo.preview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    maxLines: 20,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SHA256: ${logInfo.hash.substring(0, 16)}...',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class LogFileInfo {
  final File file;
  final int size;
  final DateTime modified;
  final String preview;
  final String hash;

  LogFileInfo({
    required this.file,
    required this.size,
    required this.modified,
    required this.preview,
    required this.hash,
  });
}
