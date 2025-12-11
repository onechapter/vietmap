/// Result of log upload operation
class UploadResult {
  final bool success;
  final String? id;
  final String? error;
  final DateTime timestamp;

  UploadResult({
    required this.success,
    this.id,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory UploadResult.success(String id) {
    return UploadResult(success: true, id: id);
  }

  factory UploadResult.failure(String error) {
    return UploadResult(success: false, error: error);
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'id': id,
        'error': error,
        'timestamp': timestamp.toIso8601String(),
      };
}
