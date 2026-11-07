package com.nettia.com

import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/// Canal "nettia/licencia" (SPEC-005 RF6): entrega el ANDROID_ID y la huella
/// SHA-256 del certificado con que se firmó el APK.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nettia/licencia")
            .setMethodCallHandler { call, result ->
                if (call.method == "datos") {
                    try {
                        result.success(mapOf("androidId" to androidId(), "huella" to huella()))
                    } catch (e: Exception) {
                        result.error("sin_datos", null, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun androidId(): String =
        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""

    @Suppress("DEPRECATION")
    private fun certificado(): ByteArray? {
        val pm = packageManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            val firmas = info.signingInfo ?: return null
            // Con varios firmantes no se acepta: Nettia se firma con una sola clave.
            if (firmas.hasMultipleSigners()) return null
            firmas.signingCertificateHistory?.lastOrNull()?.toByteArray()
        } else {
            val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            info.signatures?.singleOrNull()?.toByteArray()
        }
    }

    private fun huella(): String {
        val cert = certificado() ?: return ""
        return MessageDigest.getInstance("SHA-256").digest(cert)
            .joinToString(":") { "%02X".format(it) }
    }
}
