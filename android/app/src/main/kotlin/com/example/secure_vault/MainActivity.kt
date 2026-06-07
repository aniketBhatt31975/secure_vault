package com.example.secure_vault

import com.example.secure_vault.channels.KeystoreChannel

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        KeystoreChannel(MethodChannel(messenger, KeystoreChannel.CHANNEL_NAME), this)
       
    }
}
