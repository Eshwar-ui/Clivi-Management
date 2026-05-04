import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/file_utils.dart'; // Import created in previous step

class FileUploadWidget extends StatefulWidget {
  final Function(String fileName, List<int> bytes) onFileSelected;
  final String? label;
  final List<String>? allowedExtensions;

  const FileUploadWidget({
    super.key,
    required this.onFileSelected,
    this.label,
    this.allowedExtensions,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  String? _selectedFileName;
  String? _fileSize;

  Future<void> _pickFile() async {
    final file = await FileUtils.pickFile(
      allowedExtensions: widget.allowedExtensions,
      type: FileType.custom, // ensure custom type when filtering extensions
    );

    if (file != null) {
      setState(() {
        _selectedFileName = file.name;
        _fileSize = FileUtils.formatFileSize(file.size);
      });

      if (file.bytes != null) {
        widget.onFileSelected(file.name, file.bytes!);
      } else {
        // Handle case where bytes might be null (e.g. IO file path, but on web/mobile likely bytes or path)
        // For simplicity assuming bytes available or use platform file
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? 'Select file to upload',
                        style: TextStyle(
                          color: _selectedFileName != null
                              ? Colors.black
                              : Colors.grey,
                          fontWeight: _selectedFileName != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (_selectedFileName != null)
                        Text(
                          _fileSize ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (_selectedFileName != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedFileName = null;
                        _fileSize = null;
                      });
                      // Invoke callback with empty to clear if needed?
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
