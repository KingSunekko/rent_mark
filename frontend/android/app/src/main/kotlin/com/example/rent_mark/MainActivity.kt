package com.example.rent_mark

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.ActivityNotFoundException
import android.net.Uri

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rentmark/maps")
            .setMethodCallHandler { call, result ->
                if (call.method != "openSearch") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val query = call.argument<String>("query")?.trim()
                if (query.isNullOrEmpty() || query.length > 1000) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                val uri = Uri.Builder().scheme("https").authority("www.google.com")
                    .appendPath("maps").appendPath("search").appendPath("")
                    .appendQueryParameter("api", "1").appendQueryParameter("query", query).build()
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, uri))
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                } catch (_: SecurityException) {
                    result.success(false)
                }
            }
    }
}
