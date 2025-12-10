import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_and_media_picker/src/widgets/file_preview_widget.dart';
import 'package:flutter_file_and_media_picker/src/widgets/media_picker.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedFile;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Media Picker'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null) ...[
              FilePreview(file: _selectedFile!),
              const SizedBox(height: 20),
              Text(
                'Selected: ${_selectedFile!.path.split('/').last}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _clearSelection,
                child: const Text('Clear Selection'),
              ),
              const SizedBox(height: 30),
            ],
            ElevatedButton.icon(
              onPressed: _openMediaPicker,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose Media'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openMediaPicker,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openMediaPicker() async {
    // No permission check needed - it's handled natively
    setState(() => _isLoading = true);

    // Show the media picker
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => WhatsAppMediaPicker(
        onFileSelected: (file) {
          Navigator.pop(context);
          setState(() {
            _selectedFile = file;
            _isLoading = false;
          });

          if (file != null) {
            _showSnackBar('File selected successfully');
          }
        },
        title: 'Choose media source',
        showCamera: true,
        showGallery: true,
        showSystemFiles: true,
      ),
    ).then((_) {
      setState(() => _isLoading = false);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}