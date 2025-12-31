package com.bjp.dakshin_pashchim

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var fileCallback: ValueCallback<Array<Uri>>? = null
    private val FILE_REQUEST = 2025

    private val CHANNEL = "file_picker_channel"
    private val MEDIA_SCANNER_CHANNEL = "media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Flutter → Android calls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openPicker") {
                    openFileChooser()
                    result.success(true)
                }
            }
    }
 

    // Open Android gallery
    private fun openFileChooser() {
        val intent = Intent(Intent.ACTION_GET_CONTENT)
        intent.type = "*/*"
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        startActivityForResult(Intent.createChooser(intent, "Select File"), FILE_REQUEST)
    }

    // Handle gallery result and send back to WebView
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == FILE_REQUEST) {
            val result =
                if (resultCode == Activity.RESULT_OK && data?.data != null)
                    arrayOf(data.data!!)
                else emptyArray()

            fileCallback?.onReceiveValue(result)
            fileCallback = null
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    // WebView file chooser
    inner class MyWebChrome : WebChromeClient() {
        override fun onShowFileChooser(
            webView: WebView?,
            filePathCallback: ValueCallback<Array<Uri>>,
            fileChooserParams: FileChooserParams
        ): Boolean {

            fileCallback = filePathCallback
            openFileChooser()
            return true
        }
    }
}
