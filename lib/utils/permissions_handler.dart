import 'package:flutter/services.dart';

class PermissionsHandler {
  static const MethodChannel _channel = MethodChannel('permissions_channel');


  static Future<bool> checkAndRequestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAndRequestPermissions');
      return result ?? false;
    } on PlatformException {
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