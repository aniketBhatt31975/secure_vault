package com.example.secure_vault.channels

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class KeystoreChannel(channel: MethodChannel, private val context: Context) : MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.example.secure_vault/keystore"
        private const val KEY_ALIAS = "secure_vault_master_key"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val PREFS_NAME = "secure_vault_prefs"
        private const val PREF_ENCRYPTED_KEY = "encrypted_data_key"
        private const val PREF_KEY_IV = "data_key_iv"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_TAG_LENGTH = 128
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getOrCreateKey" -> {
                try {
                    result.success(getOrCreateKey())
                } catch (e: Exception) {
                    result.error("KEYSTORE_ERROR", e.message, null)
                }
            }
            "deleteKey" -> {
                try {
                    deleteKey()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("KEYSTORE_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getMasterKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)
            keyGenerator.init(
                KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build()
            )
            keyGenerator.generateKey()
        }
        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }

    private fun getOrCreateKey(): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val encryptedKeyB64 = prefs.getString(PREF_ENCRYPTED_KEY, null)
        val ivB64 = prefs.getString(PREF_KEY_IV, null)

        val masterKey = getMasterKey()

        return if (encryptedKeyB64 != null && ivB64 != null) {
            // Decrypt the stored data key using the master key
            val encryptedKey = Base64.decode(encryptedKeyB64, Base64.NO_WRAP)
            val iv = Base64.decode(ivB64, Base64.NO_WRAP)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, masterKey, GCMParameterSpec(GCM_TAG_LENGTH, iv))
            val dataKeyBytes = cipher.doFinal(encryptedKey)
            Base64.encodeToString(dataKeyBytes, Base64.NO_WRAP)
        } else {
            // Generate a new random 256-bit data key
            val dataKeyBytes = ByteArray(32)
            java.security.SecureRandom().nextBytes(dataKeyBytes)

            // Encrypt the data key with the master key
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, masterKey)
            val encryptedKey = cipher.doFinal(dataKeyBytes)
            val iv = cipher.iv

            prefs.edit()
                .putString(PREF_ENCRYPTED_KEY, Base64.encodeToString(encryptedKey, Base64.NO_WRAP))
                .putString(PREF_KEY_IV, Base64.encodeToString(iv, Base64.NO_WRAP))
                .apply()

            Base64.encodeToString(dataKeyBytes, Base64.NO_WRAP)
        }
    }

    private fun deleteKey() {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        if (keyStore.containsAlias(KEY_ALIAS)) {
            keyStore.deleteEntry(KEY_ALIAS)
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(PREF_ENCRYPTED_KEY)
            .remove(PREF_KEY_IV)
            .apply()
    }
}
