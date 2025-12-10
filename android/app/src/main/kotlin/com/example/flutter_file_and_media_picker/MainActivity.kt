package com.example.flutter_file_and_media_picker

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
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
    private val CHANNEL = "file_picker_channel"
    private var pendingResult: MethodChannel.Result? = null
    private var currentPhotoPath: String = ""

    // Request codes
    private val PERMISSION_REQUEST_CAMERA = 1001
    private val PERMISSION_REQUEST_STORAGE = 1002
    private val REQUEST_PICK_IMAGE = 2001
    private val REQUEST_PICK_VIDEO = 2002
    private val REQUEST_PICK_FILE = 2003
    private val REQUEST_TAKE_PICTURE = 2004

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            pendingResult = result
            when (call.method) {
                "pickImage" -> pickImage()
                "pickVideo" -> pickVideo()
                "pickFile" -> pickFile()
                "takePicture" -> takePicture()
                "checkPermissions" -> checkAndRequestPermissions()
                "checkCameraPermission" -> result.success(checkCameraPermission())
                "checkStoragePermission" -> result.success(checkStoragePermission())
                "openSettings" -> openAppSettings()
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndRequestPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }

        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_STORAGE)
    }

    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_MEDIA_IMAGES
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            PERMISSION_REQUEST_CAMERA
        )
    }

    private fun requestStoragePermission() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }

        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_STORAGE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        when (requestCode) {
            PERMISSION_REQUEST_CAMERA -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    pendingResult?.success(true)
                    // If takePicture was pending, start it now
                    takePicture()
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
                }
            }
            PERMISSION_REQUEST_STORAGE -> {
                if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                    pendingResult?.success(true)
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                }
            }
        }
        pendingResult = null
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
        pendingResult?.success(null)
        pendingResult = null
    }

    private fun pickImage() {
        if (!checkStoragePermission()) {
            requestStoragePermission()
            return
        }

        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        startActivityForResult(intent, REQUEST_PICK_IMAGE)
    }

    private fun pickVideo() {
        if (!checkStoragePermission()) {
            requestStoragePermission()
            return
        }

        val intent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
        startActivityForResult(intent, REQUEST_PICK_VIDEO)
    }

    private fun pickFile() {
        if (!checkStoragePermission()) {
            requestStoragePermission()
            return
        }

        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(Intent.createChooser(intent, "Select File"), REQUEST_PICK_FILE)
    }

    private fun takePicture() {
        if (!checkCameraPermission()) {
            requestCameraPermission()
            return
        }

        try {
            val photoFile = createImageFile()
            val photoURI = FileProvider.getUriForFile(
                this,
                "com.example.flutter_file_and_media_picker.fileprovider",
                photoFile
            )

            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
            }
            startActivityForResult(intent, REQUEST_TAKE_PICTURE)
        } catch (e: Exception) {
            pendingResult?.error("FILE_ERROR", "Failed to create image file: ${e.message}", null)
            pendingResult = null
        }
    }

    private fun createImageFile(): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        return File.createTempFile(
            "JPEG_${timeStamp}_",
            ".jpg",
            storageDir
        ).apply {
            currentPhotoPath = absolutePath
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (resultCode != Activity.RESULT_OK) {
            pendingResult?.error("CANCELLED", "User cancelled the operation", null)
            pendingResult = null
            return
        }

        when (requestCode) {
            REQUEST_PICK_IMAGE, REQUEST_PICK_VIDEO, REQUEST_PICK_FILE -> {
                val uri = data?.data
                if (uri != null) {
                    val path = getPathFromUri(uri)
                    pendingResult?.success(path)
                } else {
                    pendingResult?.error("NO_DATA", "No file selected", null)
                }
                pendingResult = null
            }
            REQUEST_TAKE_PICTURE -> {
                if (currentPhotoPath.isNotEmpty()) {
                    pendingResult?.success(currentPhotoPath)
                } else {
                    pendingResult?.error("CAPTURE_FAILED", "Failed to capture image", null)
                }
                pendingResult = null
            }
        }
    }

    private fun getPathFromUri(uri: Uri): String {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = "FILE_${timeStamp}"
            val file = File(cacheDir, fileName)

            inputStream?.use { input ->
                file.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            file.absolutePath
        } catch (e: Exception) {
            uri.path ?: ""
        }
    }
}