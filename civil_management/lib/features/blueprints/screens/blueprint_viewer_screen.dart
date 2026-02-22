import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/config/supabase_client.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/blueprint_model.dart';
import '../data/repositories/blueprint_repository.dart';

class BlueprintViewerScreen extends StatefulWidget {
  final Blueprint blueprint;

  const BlueprintViewerScreen({super.key, required this.blueprint});

  @override
  State<BlueprintViewerScreen> createState() => _BlueprintViewerScreenState();
}

class _BlueprintViewerScreenState extends State<BlueprintViewerScreen> {
  final BlueprintRepository _repository = BlueprintRepository();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  String? _signedUrl;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      final url = await _repository.getSignedUrl(
        widget.blueprint.filePath,
        expiresIn: 600, // 10 minutes
      );
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Failed to get signed URL: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.blueprint.fileName.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.blueprint.fileName),
        actions: isPdf
            ? [
                IconButton(
                  icon: const Icon(Icons.bookmark),
                  onPressed: () {
                    _pdfViewerKey.currentState?.openBookmarkView();
                  },
                ),
              ]
            : null,
      ),
      body: _buildBody(isPdf),
    );
  }

  Widget _buildBody(bool isPdf) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading file...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadSignedUrl, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_signedUrl == null) {
      return const Center(child: Text('No URL available'));
    }

    return isPdf ? _buildPdfViewer() : _buildImageViewer();
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.network(
      _signedUrl!,
      key: _pdfViewerKey,
      canShowScrollHead: false,
      canShowScrollStatus: false,
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.network(
          _signedUrl!,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const LoadingWidget(message: 'Loading Image...');
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Failed to load image: $error'));
          },
        ),
      ),
    );
  }
}
