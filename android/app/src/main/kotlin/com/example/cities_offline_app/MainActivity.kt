package com.example.cities_offline_app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "com.cities_offline_app/google_services",
        ).setMethodCallHandler { call, result ->
            if (call.method == "hasGoogleServices") {
                val hasGms = try {
                    packageManager.getPackageInfo("com.google.android.gms", 0)
                    true
                } catch (_: PackageManager.NameNotFoundException) {
                    false
                }
                result.success(hasGms)
            } else {
                result.notImplemented()
            }
        }
    }
}
