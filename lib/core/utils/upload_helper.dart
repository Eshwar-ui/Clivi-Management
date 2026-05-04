import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import 'retry_helper.dart';

/// Upload helper with retry support for reliable file uploads
class UploadHelper {
  /// Upload file bytes with automatic retry on failure
  static Future<String> uploadWithRetry({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    int maxRetries = 3,
  }) async {
    return RetryHelper.withRetry(() async {
      logger.i('Uploading to $bucket/$path (${bytes.length} bytes)');

      await supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true, // Allows retry without conflict
              contentType: contentType,
            ),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(path);
      logger.i('Upload complete: $url');
      return url;
    }, maxAttempts: maxRetries);
  }

  /// Generate unique file path with timestamp to prevent collisions
  static String generateUniquePath(String folder, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final baseName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final sanitized = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '$folder/${sanitized}_$timestamp.$extension';
  }
}
