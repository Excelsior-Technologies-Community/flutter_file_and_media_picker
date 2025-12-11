## flutter_media_picker

A Flutter plugin for picking media (images, files) from Camera, Gallery, or System Files with a clean, customizable UI. Inspired by WhatsApp's media picker. Works seamlessly with Android and iOS.

## ✨ Features
- Pick images from Camera
- Pick images from Gallery
- Pick any file from System File Manager
- Customizable dialog UI
- Handles loading state during selection
- Fully Flutter/Dart-based with native MethodChannel support

## ✨ Preview
![screen-20251211-1513302](https://github.com/user-attachments/assets/9a29c9e7-57e4-4d3d-9b2b-6ade3dee3b26)


## 📦 Installation
Add this to your pubspec.yaml:
```
dependencies:
  flutter_media_picker:
    path: ../flutter_media_picker  # Your path path
```
from git:
```
dependencies:
  flutter_image_crop:
    git:
      url: https://github.com/yourusername/flutter_image_crop.git  # Your github path
```
Then run:
```
flutter pub get
```
## 📁 Project Structure
```
flutter_media_picker/
├── android/          # Android native code (MethodChannel, permissions)
├── lib/              # Dart code
│   ├── src/widgets/  # Media picker & preview widgets
│   └── flutter_media_picker.dart  # Library entry point
├── example/          # Example Flutter app
├── pubspec.yaml      # Plugin config
├── README.md         # Documentation

```
## 🔧 Usage
Example:
```
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_media_picker/flutter_media_picker.dart';

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
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.file_copy_sharp, size: 80, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text('Selected: ${_selectedFile!.path.split('/').last}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _selectedFile = null),
                child: const Text('Clear Selection'),
              ),
            ],
            ElevatedButton(
              onPressed: _openMediaPicker,
              child: const Text('Pick Media'),
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

```
## ⚡MethodChannel Support

The plugin uses MethodChannel:
| Method        | Description                |
|---------------|----------------------------|
| `openCamera`  | Opens device camera        |
| `openGallery` | Opens device gallery       |
| `openFiles`   | Opens system file manager  |

## 🔑Permissions (Android)
Add to AndroidManifest.xml:
```
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

```
For Android 13+:
```
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```
## 📜 License
MIT License
```
Copyright (c) 2025 Excelsior Technologies

Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the "Software"), to deal  
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell  
copies of the Software, and to permit persons to whom the Software is  
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all  
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
