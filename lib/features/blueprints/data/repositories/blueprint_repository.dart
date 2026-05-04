import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/blueprint_model.dart';

class BlueprintRepository {
  final SupabaseClient _client;

  BlueprintRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Fetches all blueprints for a project and groups them into folders.
  ///
  /// The logic for what a site_manager can see is handled by RLS policies.
  Future<List<BlueprintFolder>> getBlueprintFolders(String projectId) async {
    try {
      final response = await _client
          .from('blueprints')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      final blueprints = (response as List)
          .map((json) => Blueprint.fromJson(json))
          .toList();

      return BlueprintFolder.fromBlueprints(blueprints);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch blueprint folders: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Fetches all blueprint files within a specific folder for a project.
  Future<List<Blueprint>> getBlueprintFiles(
    String projectId,
    String folderName,
  ) async {
    try {
      final response = await _client
          .from('blueprints')
          .select()
          .eq('project_id', projectId)
          .eq('folder_name', folderName)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Blueprint.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch blueprint files: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Uploads a file and creates a blueprint record.
  /// Generates unique filenames to avoid conflicts with existing files.
  /// For web: pass fileBytes. For mobile: pass file with valid path.
  Future<Blueprint> uploadBlueprint({
    required String projectId,
    required String folderName,
    required bool isAdminOnly,
    required File file,
    required String uploaderId,
    required bool isAdminUser,
    Uint8List? fileBytes, // Optional: for web uploads
  }) async {
    final originalFileName = file.path.split('/').last;
    final fileExtension = originalFileName.contains('.')
        ? '.${originalFileName.split('.').last}'
        : '';
    final baseFileName = originalFileName.contains('.')
        ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
        : originalFileName;

    // Generate a unique filename by checking if it exists and appending timestamp if needed
    String fileName = originalFileName;
    String filePath = '$projectId/$folderName/$fileName';

    // Check if file_path already exists in database
    final existingFiles = await _client
        .from('blueprints')
        .select('file_path')
        .eq('file_path', filePath);

    if ((existingFiles as List).isNotEmpty) {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = '${baseFileName}_$timestamp$fileExtension';
      filePath = '$projectId/$folderName/$fileName';
    }

    // Site managers are never allowed to create admin-only files (defensive)
    final effectiveIsAdminOnly = isAdminUser ? isAdminOnly : false;

    try {
      // 1. Upload file to storage
      // Use uploadBinary for web (dart:io.File not supported on web)
      // Use upload for mobile/desktop
      if (kIsWeb && fileBytes != null) {
        // For web: use bytes directly
        await _client.storage
            .from('blueprints')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } else if (!kIsWeb) {
        // For mobile/desktop: use regular upload with File
        await _client.storage
            .from('blueprints')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } else {
        // Fallback: try reading bytes from file
        final bytes = await file.readAsBytes();
        await _client.storage
            .from('blueprints')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      }

      // 2. Get the public URL for the uploaded file
      final fileUrl = _client.storage.from('blueprints').getPublicUrl(filePath);

      // 3. Create record in database
      final response = await _client
          .from('blueprints')
          .insert({
            'project_id': projectId,
            'folder_name': folderName,
            'file_name': fileName,
            'file_path': filePath,
            'file_url': fileUrl,
            'is_admin_only': effectiveIsAdminOnly,
            'uploader_id': uploaderId,
          })
          .select()
          .single();

      return Blueprint.fromJson(response);
    } on StorageException catch (e) {
      logger.e('Failed to upload blueprint file: ${e.message}');
      throw StorageUploadException.fromStorageException(e);
    } on PostgrestException catch (e) {
      // If db insert fails, we should try to clean up the uploaded file
      try {
        await _client.storage.from('blueprints').remove([filePath]);
      } catch (cleanupError) {
        // Log cleanup failure for monitoring orphaned files
        logger.w(
          'Failed to cleanup uploaded file after DB error: $cleanupError',
        );
      }
      logger.e('Failed to create blueprint record: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Deletes a blueprint file and its database record.
  Future<void> deleteBlueprint(String blueprintId) async {
    try {
      // First, get the file path to delete from storage
      final response = await _client
          .from('blueprints')
          .select('file_path')
          .eq('id', blueprintId)
          .single();

      final filePath = response['file_path'] as String?;

      if (filePath == null) {
        throw DatabaseException('Blueprint not found or file path is missing.');
      }

      // Delete from database (which will cascade to storage via trigger, or do it manually)
      // Let's do it manually for explicit control.

      // 1. Delete from DB
      await _client.from('blueprints').delete().eq('id', blueprintId);

      // 2. Delete from Storage
      await _client.storage.from('blueprints').remove([filePath]);
    } on PostgrestException catch (e) {
      logger.e('Failed to delete blueprint record: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    } on StorageException catch (e) {
      logger.e('Failed to delete blueprint file: ${e.message}');
      // The DB record might be gone, but the file is orphaned.
      // This state is not ideal, but we notify of the error.
      throw StorageDeleteException.fromStorageException(e);
    }
  }

  /// Get a signed URL for viewing a private file
  /// URL is valid for the specified duration (default 300 seconds = 5 minutes)
  Future<String> getSignedUrl(String filePath, {int expiresIn = 300}) async {
    try {
      final signedUrl = await _client.storage
          .from('blueprints')
          .createSignedUrl(filePath, expiresIn);
      return signedUrl;
    } on StorageException catch (e) {
      logger.e('Failed to generate signed URL: ${e.message}');
      throw StorageUploadException.fromStorageException(e);
    }
  }
}
