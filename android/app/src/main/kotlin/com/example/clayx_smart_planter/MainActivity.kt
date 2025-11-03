package com.example.clayx_smart_planter

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import java.security.KeyStore

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Clear corrupted Android Keystore on first launch
        try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)
            keyStore.deleteEntry("FlutterSecureStoragePluginKey")
        } catch (e: Exception) {
            // Ignore errors
        }
    }
}