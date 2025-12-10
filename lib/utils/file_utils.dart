import 'dart:io';

class FileUtils {
  static bool isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return [
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
      'tiff', 'tif', 'svg', 'ico'
    ].contains(ext);
  }

  static bool isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return [
      'mp4', 'mov', 'avi', 'wmv', 'flv', 'mkv',
      '3gp', 'webm', 'm4v', 'mpg', 'mpeg'
    ].contains(ext);
  }

  static bool isAudioFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return [
      'mp3', 'wav', 'aac', 'flac', 'm4a',
      'wma', 'ogg', 'opus'
    ].contains(ext);
  }

  static bool isDocumentFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return [
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'txt', 'rtf', 'csv', 'html', 'xml', 'json'
    ].contains(ext);
  }

  static bool isArchiveFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext);
  }

  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  static String getFileName(String path) {
    return path.split('/').last;
  }

  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<bool> isFileReadable(File file) async {
    try {
      await file.open();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isValidMediaFile(File file, {double maxSizeMB = 25}) async {
    // Check if file exists
    if (!await file.exists()) return false;

    // Check file size
    final sizeInMB = await file.length() / (1024 * 1024);
    if (sizeInMB > maxSizeMB) return false;

    // Check if it's a supported media file
    final path = file.path;
    return isImageFile(path) || isVideoFile(path) || isAudioFile(path);
  }
}