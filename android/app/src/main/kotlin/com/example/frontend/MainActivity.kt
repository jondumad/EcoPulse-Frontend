package com.example.frontend

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Fix for Vivo/iQOO devices: Disable hardware acceleration to avoid pixel format 0x3b error
        // This prevents "GetSize: Unrecognized pixel format: 0x3b" crashes
        try {
            window.clearFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
        } catch (e: Exception) {
            // Fallback: if clearFlags fails, continue normally
            e.printStackTrace()
        }
    }
}