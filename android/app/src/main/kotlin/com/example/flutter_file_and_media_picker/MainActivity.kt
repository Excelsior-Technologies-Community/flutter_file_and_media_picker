package com.example.flutter_file_and_media_picker

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "media_picker_channel"

    // Request codes
    private val REQUEST_CAMERA = 1001
    private val REQUEST_GALLERY = 1002
    private val REQUEST_FILE = 1003

    // Permission request codes
    private val PERMISSION_CAMERA = 1004
    private val PERMISSION_STORAGE = 1005

    // Result callbacks
    private var cameraResult: MethodChannel.Result? = null
    private var galleryResult: MethodChannel.Result? = null
    private var fileResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null

    // File for camera photo
    private var cameraPhotoFile: File? = null

    // Track pending operation
    private var pendingOperation: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d(TAG, "✅ MainActivity: Configuring Flutter engine")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "📞 MethodChannel: ${call.method}")

            when (call.method) {
                // Permission checks
                "checkCameraPermission" -> {
                    val hasPermission = checkCameraPermission()
                    Log.d(TAG, "checkCameraPermission: $hasPermission")
                    result.success(hasPermission)
                }
                "checkStoragePermission" -> {
                    val hasPermission = checkStoragePermission()
                    Log.d(TAG, "checkStoragePermission: $hasPermission")
                    result.success(hasPermission)
                }

                // Permission requests
                "requestCameraPermission" -> {
                    permissionResult = result
                    pendingOperation = "request_camera_permission"
                    requestCameraPermission()
                }
                "requestStoragePermission" -> {
                    permissionResult = result
                    pendingOperation = "request_storage_permission"
                    requestStoragePermission()
                }

                // Media picker operations
                "openCamera" -> {
                    cameraResult = result
                    pendingOperation = "camera"
                    openCamera()
                }
                "openGallery" -> {
                    galleryResult = result
                    pendingOperation = "gallery"
                    openGallery()
                }
                "openSystemFiles" -> {
                    fileResult = result
                    pendingOperation = "files"
                    openSystemFiles()
                }

                // App settings
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }

                else -> {
                    Log.w(TAG, "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    // ========== PERMISSION METHODS ==========

    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
        } else {
            // Android 6-12
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestCameraPermission() {
        Log.d(TAG, "Requesting camera permission")
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            PERMISSION_CAMERA
        )
    }

    private fun requestStoragePermission() {
        Log.d(TAG, "Requesting storage permission")
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES
            )
        } else {
            // Android 6-12
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }

        ActivityCompat.requestPermissions(this, permissions, PERMISSION_STORAGE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        Log.d(TAG, "Permission result: requestCode=$requestCode, granted=$isGranted")

        when (requestCode) {
            PERMISSION_CAMERA -> {
                if (pendingOperation == "request_camera_permission") {
                    permissionResult?.success(isGranted)
                    permissionResult = null
                } else if (pendingOperation == "camera" && isGranted) {
                    openCamera()
                } else if (pendingOperation == "camera" && !isGranted) {
                    cameraResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
                    cameraResult = null
                }
            }

            PERMISSION_STORAGE -> {
                if (pendingOperation == "request_storage_permission") {
                    permissionResult?.success(isGranted)
                    permissionResult = null
                } else if (pendingOperation == "gallery" && isGranted) {
                    openGallery()
                } else if (pendingOperation == "files" && isGranted) {
                    openSystemFiles()
                } else if ((pendingOperation == "gallery" || pendingOperation == "files") && !isGranted) {
                    galleryResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                    fileResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                    galleryResult = null
                    fileResult = null
                }
            }
        }

        pendingOperation = null
    }

    // ========== CAMERA ==========

    private fun openCamera() {
        Log.d(TAG, "📸 Opening camera")

        // Check permission
        if (!checkCameraPermission()) {
            Log.d(TAG, "Camera permission not granted, requesting...")
            requestCameraPermission()
            return
        }

        try {
            val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)

            // Create file for the photo
            cameraPhotoFile = createImageFile()
            Log.d(TAG, "📁 Camera file created: ${cameraPhotoFile?.absolutePath}")

            if (cameraPhotoFile != null) {
                // ✅ IMPORTANT: CORRECT AUTHORITY
                val photoURI = FileProvider.getUriForFile(
                    this,
                    "com.example.flutter_file_and_media_picker.fileprovider", // 🔥 આ authority
                    cameraPhotoFile!!
                )

                Log.d(TAG, "📎 Photo URI: $photoURI")

                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                takePictureIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                startActivityForResult(takePictureIntent, REQUEST_CAMERA)
            } else {
                cameraResult?.error("ERROR", "Could not create image file", null)
                cameraResult = null
                pendingOperation = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Camera error: ${e.message}", e)
            cameraResult?.error("ERROR", e.message, null)
            cameraResult = null
            pendingOperation = null
        }
    }

    // ========== GALLERY ==========

    private fun openGallery() {
        Log.d(TAG, "🖼️ Opening gallery")

        // Check permission
        if (!checkStoragePermission()) {
            Log.d(TAG, "Storage permission not granted, requesting...")
            requestStoragePermission()
            return
        }

        try {
            val pickPhoto = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            pickPhoto.type = "image/*"
            pickPhoto.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)

            startActivityForResult(pickPhoto, REQUEST_GALLERY)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Gallery error: ${e.message}", e)
            galleryResult?.error("ERROR", e.message, null)
            galleryResult = null
            pendingOperation = null
        }
    }

    // ========== SYSTEM FILES ==========

    private fun openSystemFiles() {
        Log.d(TAG, "📁 Opening system files")

        // Check permission
        if (!checkStoragePermission()) {
            Log.d(TAG, "Storage permission not granted, requesting...")
            requestStoragePermission()
            return
        }

        try {
            val intent = Intent(Intent.ACTION_GET_CONTENT)
            intent.type = "*/*"
            intent.addCategory(Intent.CATEGORY_OPENABLE)

            startActivityForResult(Intent.createChooser(intent, "Select File"), REQUEST_FILE)
        } catch (e: Exception) {
            Log.e(TAG, "❌ File picker error: ${e.message}", e)
            fileResult?.error("ERROR", e.message, null)
            fileResult = null
            pendingOperation = null
        }
    }

    // ========== ACTIVITY RESULT HANDLER ==========

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d(TAG, "📱 Activity result: requestCode=$requestCode, resultCode=$resultCode")

        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                REQUEST_CAMERA -> {
                    Log.d(TAG, "✅ Camera photo captured: ${cameraPhotoFile?.absolutePath}")
                    cameraResult?.success(cameraPhotoFile?.absolutePath)
                    cameraResult = null
                }
                REQUEST_GALLERY -> {
                    val selectedImage = data?.data
                    Log.d(TAG, "✅ Gallery selected: $selectedImage")
                    galleryResult?.success(selectedImage?.toString())
                    galleryResult = null
                }
                REQUEST_FILE -> {
                    val selectedFile = data?.data
                    Log.d(TAG, "✅ File selected: $selectedFile")
                    fileResult?.success(selectedFile?.toString())
                    fileResult = null
                }
            }
        } else {
            Log.d(TAG, "❌ Activity cancelled")
            when (requestCode) {
                REQUEST_CAMERA -> {
                    cameraResult?.success(null)
                    cameraResult = null
                }
                REQUEST_GALLERY -> {
                    galleryResult?.success(null)
                    galleryResult = null
                }
                REQUEST_FILE -> {
                    fileResult?.success(null)
                    fileResult = null
                }
            }
        }

        cameraPhotoFile = null
        pendingOperation = null
    }

    // ========== UTILITY FUNCTIONS ==========

    private fun createImageFile(): File? {
        return try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val imageFileName = "JPEG_${timeStamp}_"

            val storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            storageDir?.mkdirs()

            File.createTempFile(
                imageFileName,  /* prefix */
                ".jpg",         /* suffix */
                storageDir      /* directory */
            ).also {
                Log.d(TAG, "📄 Created image file: ${it.absolutePath}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error creating image file: ${e.message}", e)
            null
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            val uri = Uri.fromParts("package", packageName, null)
            intent.data = uri
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening app settings: ${e.message}", e)
        }
    }
}