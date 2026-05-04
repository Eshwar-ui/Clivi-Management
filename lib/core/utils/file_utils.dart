import 'package:file_picker/file_picker.dart';

class FileUtils {
  /// Pick a single file
  static Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    // FilePicker requires FileType.custom when passing allowedExtensions.
    final hasExtensions =
        allowedExtensions != null && allowedExtensions.isNotEmpty;
    final effectiveType = (hasExtensions || type == FileType.custom)
        ? FileType.custom
        : type;
    final sanitizedExtensions =
        allowedExtensions?.map(_stripDot).toList();

    // Avoid crashing if caller asked for custom but forgot extensions.
    if (effectiveType == FileType.custom && sanitizedExtensions == null) {
      // Fall back to any without filters.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      return _firstOrNull(result);
    }

    final result = await FilePicker.platform.pickFiles(
      type: effectiveType,
      allowedExtensions: sanitizedExtensions,
      withData: true,
    );

    return _firstOrNull(result);
  }

  /// Pick multiple files
  static Future<List<PlatformFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    final hasExtensions =
        allowedExtensions != null && allowedExtensions.isNotEmpty;
    final effectiveType = (hasExtensions || type == FileType.custom)
        ? FileType.custom
        : type;
    final sanitizedExtensions =
        allowedExtensions?.map(_stripDot).toList();

    if (effectiveType == FileType.custom && sanitizedExtensions == null) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );
      return result?.files ?? [];
    }

    final result = await FilePicker.platform.pickFiles(
      type: effectiveType,
      allowedExtensions: sanitizedExtensions,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      return result.files;
    }
    return [];
  }

  /// Get file size string (e.g., "1.5 MB")
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    // var i = (bytes.bitLength - 1) ~/ 10; // Log2 approx
    // i would be roughly index. But simpler approach:

    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(1)} GB";
  }

  static String _stripDot(String ext) =>
      ext.startsWith('.') ? ext.substring(1) : ext;

  static PlatformFile? _firstOrNull(FilePickerResult? result) =>
      (result != null && result.files.isNotEmpty) ? result.files.first : null;
}
