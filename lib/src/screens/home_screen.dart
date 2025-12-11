import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_and_media_picker/src/widgets/media_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Media Picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null) ...[
              Image.file(
                _selectedFile!,
                width: 300,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.file_copy_sharp, size: 80, color: Colors.red);
                },
              ),
              const SizedBox(height: 10),
              Text('Selected: ${_selectedFile!.path.split('/').last}'),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _openMediaPicker,
                  child: const Text('Pick Media & File'),
                ),
                const SizedBox(width: 20),
                if (_selectedFile != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    ),
                    onPressed: () {
                      setState(() => _selectedFile = null);
                    },
                    child: const Text('Clear Selection'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMediaPicker() {
    showDialog(
      context: context,
      builder: (_) => WhatsAppMediaPicker(
        onFileSelected: (file) {
          Navigator.pop(context);
          setState(() => _selectedFile = file);
        },
      ),
    );
  }
}
