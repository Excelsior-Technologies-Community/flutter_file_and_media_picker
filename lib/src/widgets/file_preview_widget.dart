import 'dart:io';
import 'package:flutter/material.dart';

class FilePreview extends StatelessWidget {
  final File file;
  final double size;
  final VoidCallback? onRemove;

  const FilePreview({
    super.key,
    required this.file,
    this.size = 200, // ✅ Increased size for better preview
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final path = file.path;
    final isContentUri = path.startsWith('content://');

    // ✅ DON'T use file.lengthSync() for content URIs
    String fileSize = "Unknown";
    String fileName = "File";

    try {
      if (!isContentUri) {
        // Regular file
        if (file.existsSync()) {
          fileSize = _formatFileSize(file.lengthSync());
        }
        fileName = _getFileName(path);
      } else {
        // Content URI - show placeholder
        fileSize = "Media File";
        fileName = _getContentUriName(path);
      }
    } catch (e) {
      // If any error occurs, show placeholder
      return _buildContentUriPreview(path);
    }

    // Check if it's an image file
    final isImage = _isImageFile(path);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isContentUri ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isContentUri ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image preview (only for regular files, not content URIs)
          if (isImage && !isContentUri)
            _buildImagePreview(file)
          else if (isContentUri)
            _buildContentUriPreview(path)
          else
            _buildFileIcon(path),

          // File info at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fileSize,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remove button (if provided)
          if (onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder("Cannot load image");
        },
      ),
    );
  }

  Widget _buildContentUriPreview(String contentUri) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 50,
            color: Colors.blue[700],
          ),
          const SizedBox(height: 10),
          Text(
            'Gallery Image',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tap to view in gallery',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String path) {
    final icon = _getFileIcon(path);
    final color = _getFileIconColor(path);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 10),
          Text(
            _getFileExtension(path).toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isImageFile(String path) {
    try {
      final ext = path.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
    } catch (e) {
      return false;
    }
  }

  IconData _getFileIcon(String path) {
    try {
      final ext = path.split('.').last.toLowerCase();

      switch (ext) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart;
        case 'mp3':
        case 'wav':
          return Icons.audiotrack;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Icons.videocam;
        case 'zip':
        case 'rar':
          return Icons.archive;
        default:
          return Icons.insert_drive_file;
      }
    } catch (e) {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String path) {
    try {
      final ext = path.split('.').last.toLowerCase();

      switch (ext) {
        case 'pdf':
          return Colors.red;
        case 'doc':
        case 'docx':
          return Colors.blue;
        case 'xls':
        case 'xlsx':
          return Colors.green;
        case 'mp3':
        case 'wav':
          return Colors.purple;
        case 'mp4':
        case 'avi':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getFileExtension(String path) {
    try {
      final parts = path.split('.');
      return parts.length > 1 ? parts.last.toLowerCase() : 'file';
    } catch (e) {
      return 'file';
    }
  }

  String _getFileName(String path) {
    try {
      final fileName = path.split('/').last;
      if (fileName.length > 20) {
        return '${fileName.substring(0, 17)}...';
      }
      return fileName;
    } catch (e) {
      return 'File';
    }
  }

  String _getContentUriName(String uri) {
    if (uri.contains('photos.contentprovider')) {
      return 'Google Photos';
    } else if (uri.contains('media')) {
      return 'Gallery Image';
    } else if (uri.contains('document')) {
      return 'Document';
    }
    return 'Media File';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}