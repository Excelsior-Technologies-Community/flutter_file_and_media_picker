import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WhatsAppMediaPicker extends StatefulWidget {
  final Function(File? file) onFileSelected;
  final String title;
  final bool showCamera;
  final bool showGallery;
  final bool showSystemFiles;

  const WhatsAppMediaPicker({
    super.key,
    required this.onFileSelected,
    this.title = "Choose media source",
    this.showCamera = true,
    this.showGallery = true,
    this.showSystemFiles = true,
  });

  @override
  State<WhatsAppMediaPicker> createState() => _WhatsAppMediaPickerState();
}

class _WhatsAppMediaPickerState extends State<WhatsAppMediaPicker> {
  static const MethodChannel _channel = MethodChannel('media_picker_channel');
  bool _isLoading = false;
  String? _currentOperation;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: _isLoading
            ? _buildLoadingView()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildOptionsList(),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _currentOperation ?? 'Processing...',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    final List<Map<String, dynamic>> options = [];

    if (widget.showCamera) {
      options.add({
        'icon': Icons.camera_alt_rounded,
        'label': "Camera",
        'color': const Color(0xFF2196F3),
        'action': _openCamera,
      });
    }

    if (widget.showGallery) {
      options.add({
        'icon': Icons.photo_library_rounded,
        'label': "Gallery Grid",
        'color': const Color(0xFF4CAF50),
        'action': _openGallery,
      });
    }

    if (widget.showSystemFiles) {
      options.add({
        'icon': Icons.folder_open_rounded,
        'label': "System Files",
        'color': const Color(0xFFFF9800),
        'action': _openSystemFiles,
      });
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.shade300,
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) => _buildOptionItem(options[index]),
    );
  }

  Widget _buildOptionItem(Map<String, dynamic> option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option['action'],
        splashColor: Colors.grey.shade100,
        highlightColor: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: option['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(option['icon'], size: 24, color: option['color']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option['label'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(
              child: Text(
                "Cancel",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    _setLoadingState(true, "Opening camera...");
    try {
      final result = await _channel.invokeMethod<String>('openCamera');
      _handleResult(result);
    } on PlatformException catch (e) {
      _handleError("Camera", e.message);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _openGallery() async {
    _setLoadingState(true, "Opening gallery...");
    try {
      final result = await _channel.invokeMethod<String>('openGallery');
      _handleResult(result);
    } on PlatformException catch (e) {
      _handleError("Gallery", e.message);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _openSystemFiles() async {
    _setLoadingState(true, "Opening file manager...");
    try {
      final result = await _channel.invokeMethod<String>('openSystemFiles');
      _handleResult(result);
    } on PlatformException catch (e) {
      _handleError("File picker", e.message);
    } finally {
      _setLoadingState(false);
    }
  }

  void _handleResult(String? filePath) {
    if (filePath != null && filePath.isNotEmpty) {
      // On Android, some URIs may need to be converted to File via cache
      final file = File(filePath);
      widget.onFileSelected(file);
    } else {
      widget.onFileSelected(null);
    }
  }

  void _handleError(String source, String? error) {
    widget.onFileSelected(null);
    _showError("$source error: ${error ?? 'Unknown error'}");
  }

  void _setLoadingState(bool loading, [String? operation]) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _currentOperation = operation;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
