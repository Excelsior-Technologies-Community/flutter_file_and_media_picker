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
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "media_picker_channel"

    // Request codes
    private val REQUEST_CAMERA = 1001
    private val REQUEST_GALLERY = 1002
    private val REQUEST_FILE = 1003

    // Permission codes
    private val PERMISSION_CAMERA = 1004
    private val PERMISSION_STORAGE = 1005

    private var cameraResult: MethodChannel.Result? = null
    private var galleryResult: MethodChannel.Result? = null
    private var fileResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null
    private var pendingOperation: String? = null

    private var cameraPhotoFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                else -> result.notImplemented()
            }
        }
    }

    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), PERMISSION_CAMERA)
    }

    private fun requestStoragePermission() {
        val perms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(Manifest.permission.READ_MEDIA_IMAGES)
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        ActivityCompat.requestPermissions(this, perms, PERMISSION_STORAGE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED

        when(requestCode){
            PERMISSION_CAMERA -> {
                if (pendingOperation == "camera" && isGranted) openCamera()
                else cameraResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
            }
            PERMISSION_STORAGE -> {
                if (pendingOperation == "gallery" && isGranted) openGallery()
                else if (pendingOperation == "files" && isGranted) openSystemFiles()
                else {
                    galleryResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                    fileResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                }
            }
        }
    }

    private fun openCamera() {
        if (!checkCameraPermission()) {
            requestCameraPermission()
            return
        }

        try {
            val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            cameraPhotoFile = createImageFile()
            if (cameraPhotoFile != null) {
                val photoURI = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    cameraPhotoFile!!
                )
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                takePictureIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivityForResult(takePictureIntent, REQUEST_CAMERA)
            } else {
                cameraResult?.error("ERROR", "Failed to create camera file", null)
            }
        } catch (e: Exception) {
            cameraResult?.error("ERROR", e.message, null)
        }
    }

    private fun openGallery() {
        if (!checkStoragePermission()) {
            requestStoragePermission()
            return
        }

        try {
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            intent.type = "image/*"
            startActivityForResult(intent, REQUEST_GALLERY)
        } catch (e: Exception) {
            galleryResult?.error("ERROR", e.message, null)
        }
    }

    private fun openSystemFiles() {
        if (!checkStoragePermission()) {
            requestStoragePermission()
            return
        }

        try {
            val intent = Intent(Intent.ACTION_GET_CONTENT)
            intent.type = "*/*"
            intent.addCategory(Intent.CATEGORY_OPENABLE)
            startActivityForResult(Intent.createChooser(intent, "Select File"), REQUEST_FILE)
        } catch (e: Exception) {
            fileResult?.error("ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                REQUEST_CAMERA -> cameraResult?.success(cameraPhotoFile?.absolutePath)
                REQUEST_GALLERY -> {
                    val uri = data?.data
                    val tempFile = copyUriToTempFile(uri)
                    galleryResult?.success(tempFile?.absolutePath)
                }
                REQUEST_FILE -> {
                    val uri = data?.data
                    val tempFile = copyUriToTempFile(uri)
                    fileResult?.success(tempFile?.absolutePath)
                }
            }
        } else {
            when (requestCode) {
                REQUEST_CAMERA -> cameraResult?.success(null)
                REQUEST_GALLERY -> galleryResult?.success(null)
                REQUEST_FILE -> fileResult?.success(null)
            }
        }
        cameraPhotoFile = null
        pendingOperation = null
    }

    private fun createImageFile(): File? {
        return try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            storageDir?.mkdirs()
            File.createTempFile("JPEG_${timeStamp}_", ".jpg", storageDir)
        } catch (e: Exception) {
            null
        }
    }

    private fun copyUriToTempFile(uri: Uri?): File? {
        if (uri == null) return null
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "picked_file_${System.currentTimeMillis()}")
            val outStream = FileOutputStream(tempFile)
            inputStream.copyTo(outStream)
            outStream.close()
            inputStream.close()
            tempFile
        } catch (e: Exception) {
            null
        }
    }
}
