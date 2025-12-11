package com.vietmap.app

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CrashHandler(private val context: Context, private val engine: FlutterEngine) {
    private val channel: MethodChannel = MethodChannel(
        engine.dartExecutor.binaryMessenger,
        "com.vietmap.app/crash"
    )

    fun initialize() {
        // Set up uncaught exception handler
        Thread.setDefaultUncaughtExceptionHandler { thread, exception ->
            handleCrash(thread, exception)
        }

        Log.d("CrashHandler", "Initialized")
    }

    private fun handleCrash(thread: Thread, exception: Throwable) {
        try {
            val stackTrace = exception.stackTraceToString()
            val message = exception.message ?: "Unknown error"

            Log.e("CrashHandler", "Native crash: $message", exception)

            // Send to Flutter
            channel.invokeMethod("nativeCrash", mapOf(
                "crash_type" to exception.javaClass.simpleName,
                "message" to message,
                "stack_trace" to stackTrace
            ))

            // Default handler will still be called
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            defaultHandler?.uncaughtException(thread, exception)
        } catch (e: Exception) {
            Log.e("CrashHandler", "Error in crash handler", e)
        }
    }
}

