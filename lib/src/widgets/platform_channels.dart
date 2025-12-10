import 'package:flutter/services.dart';

class PlatformChannels {
  static const MethodChannel _channel = MethodChannel('media_picker_channel');

  // Media picker methods
  static Future<String?> openCamera() async {
    try {
      final result = await _channel.invokeMethod<String>('openCamera');
      return result;
    } on PlatformException catch (e) {
      throw Exception("Failed to open camera: ${e.message}");
    }
  }

  static Future<String?> openGallery() async {
    try {
      final result = await _channel.invokeMethod<String>('openGallery');
      return result;
    } on PlatformException catch (e) {
      throw Exception("Failed to open gallery: ${e.message}");
    }
  }

  static Future<String?> openSystemFiles() async {
    try {
      final result = await _channel.invokeMethod<String>('openSystemFiles');
      return result;
    } on PlatformException catch (e) {
      throw Exception("Failed to open system files: ${e.message}");
    }
  }

  // Permission methods (now using the same channel)
  static Future<bool> checkAndRequestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAndRequestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Permission error: ${e.message}");
      return false;
    }
  }

  static Future<bool> checkCameraPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkCameraPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> checkStoragePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkStoragePermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException {
      // Ignore if opening settings fails
    }
  }
}