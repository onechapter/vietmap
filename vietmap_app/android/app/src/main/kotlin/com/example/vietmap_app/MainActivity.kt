package com.example.vietmap_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val locationChannel = "com.vietmap/location_stream"
    private val foregroundChannel = "com.vietmap/foreground_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Đăng ký plugin mặc định
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Cầu EventChannel để tránh MissingPluginException; hiện stub không bắn data
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // TODO: gắn HybridService hoặc luồng location thực tế
                }

                override fun onCancel(arguments: Any?) {
                }
            })

        // Cầu MethodChannel cho TTS/foreground; stub trả về notImplemented/success
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, foregroundChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestTTS" -> {
                        // Chưa có native TTS; đánh dấu thành công để tránh lỗi
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        super.configureFlutterEngine(flutterEngine)
    }
}
