package com.mobymagic.clairediary

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Explicitly calling enableEdgeToEdge on the activity instance
        (this as? ComponentActivity)?.enableEdgeToEdge()

        super.onCreate(savedInstanceState)
    }
}
