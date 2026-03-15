package com.nasheet.bunk_alert

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDefaultWebClientId" -> {
                        val resId = resources.getIdentifier(
                            "default_web_client_id",
                            "string",
                            packageName
                        )
                        if (resId == 0) {
                            result.success(null)
                        } else {
                            result.success(getString(resId))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
