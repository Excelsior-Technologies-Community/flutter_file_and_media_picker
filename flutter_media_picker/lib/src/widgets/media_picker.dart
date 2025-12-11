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
  static const MethodChannel _channel =
  MethodChannel('flutter_media_picker_channel');

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
            style: const TextStyle(fontSize: 14, color: Colors.black54),
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
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildOptionsList() {
    final List<Map<String, dynamic>> options = [];
    if (widget.showCamera) {
      options.add({
        'icon': Icons.camera_alt_rounded,
        'label': "Camera",
        'color': Colors.blue,
        'action': _openCamera,
      });
    }
    if (widget.showGallery) {
      options.add({
        'icon': Icons.photo_library_rounded,
        'label': "Gallery",
        'color': Colors.green,
        'action': _openGallery,
      });
    }
    if (widget.showSystemFiles) {
      options.add({
        'icon': Icons.folder_open_rounded,
        'label': "Files",
        'color': Colors.orange,
        'action': _openFiles,
      });
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade300),
      itemBuilder: (_, index) => _buildOptionItem(options[index]),
    );
  }

  Widget _buildOptionItem(Map<String, dynamic> option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option['action'],
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: option['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(option['icon'], color: option['color']),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(option['label'])),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(
                child: Text("Cancel",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue))),
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async => _pickFile('openCamera');
  Future<void> _openGallery() async => _pickFile('openGallery');
  Future<void> _openFiles() async => _pickFile('openFiles');

  Future<void> _pickFile(String method) async {
    _setLoadingState(true, "Opening...");
    try {
      final path = await _channel.invokeMethod<String>(method);
      if (path != null) widget.onFileSelected(File(path));
    } on PlatformException catch (e) {
      widget.onFileSelected(null);
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool loading, [String? op]) {
    if (mounted) setState(() {
      _isLoading = loading;
      _currentOperation = op;
    });
  }
}
