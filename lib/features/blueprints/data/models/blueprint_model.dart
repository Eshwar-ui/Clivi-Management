class Blueprint {
  final String id;
  final String projectId;
  final String folderName;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final bool isAdminOnly;
  final String? uploaderId;
  final DateTime createdAt;

  const Blueprint({
    required this.id,
    required this.projectId,
    required this.folderName,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.isAdminOnly,
    this.uploaderId,
    required this.createdAt,
  });

  factory Blueprint.fromJson(Map<String, dynamic> json) {
    return Blueprint(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      folderName: json['folder_name'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String,
      isAdminOnly: json['is_admin_only'] as bool,
      uploaderId: json['uploader_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Public URL for accessing this blueprint file
  String get publicUrl => fileUrl;
}

/// A representation of a folder, derived from a list of Blueprints.
class BlueprintFolder {
  final String name;
  final int fileCount;
  final bool isAdminOnly;
  final DateTime lastModified;

  const BlueprintFolder({
    required this.name,
    required this.fileCount,
    required this.isAdminOnly,
    required this.lastModified,
  });

  /// Factory to create a list of folders from a list of blueprint files
  static List<BlueprintFolder> fromBlueprints(List<Blueprint> blueprints) {
    final Map<String, List<Blueprint>> folderMap = {};
    for (final blueprint in blueprints) {
      (folderMap[blueprint.folderName] ??= []).add(blueprint);
    }

    return folderMap.entries.map((entry) {
      final folderName = entry.key;
      final files = entry.value;

      // A folder is admin-only if ALL files within it are admin-only
      final isFolderAdminOnly = files.every((file) => file.isAdminOnly);

      // Get the most recent file's date as the folder's last modified date
      final lastModified = files
          .map((f) => f.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      return BlueprintFolder(
        name: folderName,
        fileCount: files.length,
        isAdminOnly: isFolderAdminOnly,
        lastModified: lastModified,
      );
    }).toList()..sort(
      (a, b) => b.lastModified.compareTo(a.lastModified),
    ); // Sort by most recently modified
  }
}
