import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/data/models/project_model.dart';
import '../providers/blueprints_provider.dart';

class BlueprintUploadScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? initialFolderName;

  const BlueprintUploadScreen({
    super.key,
    required this.projectId,
    this.initialFolderName,
  });

  @override
  ConsumerState<BlueprintUploadScreen> createState() =>
      _BlueprintUploadScreenState();
}

class _BlueprintUploadScreenState extends ConsumerState<BlueprintUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _folderNameController = TextEditingController();

  File? _selectedFile;
  Uint8List? _selectedFileBytes; // For web
  String? _selectedFileName; // For web
  bool _isAdminOnly = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFolderName != null) {
      _folderNameController.text = widget.initialFolderName!;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: kIsWeb, // Load bytes on web
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // On web: use bytes
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
          _selectedFile = null;
        } else {
          // On mobile: use file path
          if (result.files.single.path != null) {
            _selectedFile = File(result.files.single.path!);
          }
          _selectedFileBytes = null;
          _selectedFileName = null;
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if file is selected (web or mobile)
    final hasFile = kIsWeb
        ? (_selectedFileBytes != null && _selectedFileName != null)
        : _selectedFile != null;

    if (!hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uploaderId = ref.read(currentUserProvider)!.id;
    final userRole = ref.read(userRoleProvider);
    final isAdminUser =
        userRole == UserRole.admin || userRole == UserRole.superAdmin;

    try {
      // Create a temporary file for web uploads
      File fileToUpload;
      if (kIsWeb) {
        // On web: create a temporary file from bytes
        // Note: We'll handle this in the repository instead
        // For now, create a stub file that will be handled differently
        fileToUpload = File(_selectedFileName!);
      } else {
        fileToUpload = _selectedFile!;
      }

      await ref
          .read(blueprintRepositoryProvider)
          .uploadBlueprint(
            projectId: widget.projectId,
            folderName: _folderNameController.text.trim(),
            isAdminOnly: _isAdminOnly,
            file: fileToUpload,
            uploaderId: uploaderId,
            isAdminUser: isAdminUser,
            fileBytes: _selectedFileBytes, // Pass bytes for web
          );

      // Invalidate providers to refresh the lists
      ref.invalidate(allBlueprintsProvider(widget.projectId));
      ref.invalidate(blueprintFoldersProvider(widget.projectId));
      ref.invalidate(
        blueprintFilesProvider(
          projectId: widget.projectId,
          folderName: _folderNameController.text.trim(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blueprint uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.upload_file, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Blueprint files',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Separate uploads for documents and architecture diagrams',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Folder/Category Name
                    TextFormField(
                      controller: _folderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Doc Name',
                        hintText: 'e.g., Floor Plans, Electrical',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Document name cannot be empty.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Admin Only Switch
                    Consumer(
                      builder: (context, ref, _) {
                        final role = ref.watch(userRoleProvider);
                        final canToggleAdminOnly =
                            role == UserRole.admin ||
                            role == UserRole.superAdmin;
                        return SwitchListTile(
                          title: const Text('Admin Only'),
                          subtitle: Text(
                            canToggleAdminOnly
                                ? 'If enabled, only admins can see this file.'
                                : 'Visible to all (site managers cannot make admin-only)',
                          ),
                          value: _isAdminOnly && canToggleAdminOnly,
                          onChanged: canToggleAdminOnly
                              ? (value) => setState(() => _isAdminOnly = value)
                              : null,
                          secondary: const Icon(Icons.lock_outline),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Upload documentation button
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload documentation'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.primaryColor),
                        foregroundColor: theme.primaryColor,
                      ),
                    ),

                    if (_selectedFile != null || _selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  kIsWeb
                                      ? 'Selected: $_selectedFileName'
                                      : 'Selected: ${_selectedFile!.path.split('/').last}',
                                  style: TextStyle(color: Colors.green[900]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Save Button
                    AppButton(
                      text: 'Save',
                      isLoading: _isLoading,
                      onPressed: _handleUpload,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
