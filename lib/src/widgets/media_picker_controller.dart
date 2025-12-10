import 'dart:io';

import 'package:flutter_file_and_media_picker/src/widgets/platform_channels.dart';

class MediaPickerController {
  static Future<File?> pickMedia({
    required MediaSource source,
    List<String>? allowedExtensions,
    double maxFileSizeMB = 25.0,
  }) async {
    String? filePath;

    switch (source) {
      case MediaSource.camera:
        filePath = await PlatformChannels.openCamera();
        break;
      case MediaSource.gallery:
        filePath = await PlatformChannels.openGallery();
        break;
      case MediaSource.systemFiles:
        filePath = await PlatformChannels.openSystemFiles();
        break;
    }

    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);

    // Validate file size
    if (maxFileSizeMB > 0) {
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB > maxFileSizeMB) {
        throw Exception('File size exceeds ${maxFileSizeMB}MB limit');
      }
    }

    // Validate file extension
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final extension = filePath.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw Exception('File type not allowed. Allowed: $allowedExtensions');
      }
    }

    return file;
  }
}

enum MediaSource {
  camera,
  gallery,
  systemFiles,
}