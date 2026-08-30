package apptest.notey

import android.content.ActivityNotFoundException
import android.content.Intent
import android.hardware.biometrics.BiometricManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notey/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBiometricSettings" -> result.success(openBiometricSettings())
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("badArgs", "path is required", null)
                        } else {
                            try {
                                result.success(openFile(path))
                            } catch (e: Exception) {
                                result.error("openFailed", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens the file at [path] with the device's default viewer for its type
     * (PDF reader, video player, …). Returns false when the file is missing
     * or no installed app can handle it.
     */
    private fun openFile(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )
        val mime = MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(file.extension.lowercase()) ?: "*/*"
        val viewIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(viewIntent)
            true
        } catch (e: ActivityNotFoundException) {
            // No viewer for this MIME — offer the generic "open with" chooser.
            try {
                startActivity(
                    Intent.createChooser(viewIntent, null)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    /**
     * Opens the device's biometric-enrollment screen when available, falling
     * back to the generic security settings. Returns false only when no
     * suitable settings screen exists on this device.
     */
    private fun openBiometricSettings(): Boolean {
        val enrollIntent: Intent = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                Intent(Settings.ACTION_BIOMETRIC_ENROLL).apply {
                    putExtra(
                        Settings.EXTRA_BIOMETRIC_AUTHENTICATORS_ALLOWED,
                        BiometricManager.Authenticators.BIOMETRIC_WEAK or
                            BiometricManager.Authenticators.DEVICE_CREDENTIAL
                    )
                }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ->
                Intent(Settings.ACTION_BIOMETRIC_ENROLL)
            else ->
                Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        enrollIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(enrollIntent)
            true
        } catch (e: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_SECURITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
