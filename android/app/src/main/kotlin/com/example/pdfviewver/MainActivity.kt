package com.example.pdfviewver

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import android.database.Cursor
import android.provider.MediaStore
import android.content.ContentUris
import android.os.Environment
import android.content.ContentResolver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pdfviewer/file_intent"
    private var initialFileUri: String? = null
    private var initialFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            if (uri != null) {
                initialFileUri = uri.toString()
                // Try to get file path from URI
                initialFilePath = getFilePathFromUri(uri)
            }
        }
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        var filePath: String? = null
        val scheme = uri.scheme

        if (scheme == "file") {
            filePath = uri.path
        } else if (scheme == "content") {
            try {
                val cursor: Cursor? = contentResolver.query(
                    uri,
                    arrayOf(MediaStore.MediaColumns.DATA, MediaStore.MediaColumns.DISPLAY_NAME),
                    null,
                    null,
                    null
                )
                cursor?.use {
                    if (it.moveToFirst()) {
                        val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                        filePath = it.getString(columnIndex)
                    }
                }

                // If not found, try DocumentsContract
                if (filePath == null && DocumentsContract.isDocumentUri(this, uri)) {
                    val docId = DocumentsContract.getDocumentId(uri)
                    if ("primary" == uri.authority) {
                        filePath = Environment.getExternalStorageDirectory().toString() + "/" + docId
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return filePath
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialFileUri") {
                result.success(initialFileUri)
                initialFileUri = null // Clear after reading
            } else if (call.method == "getInitialFilePath") {
                result.success(initialFilePath)
                initialFilePath = null // Clear after reading
            } else {
                result.notImplemented()
            }
        }
    }
}
