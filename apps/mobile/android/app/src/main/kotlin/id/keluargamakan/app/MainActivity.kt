package id.keluargamakan.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Two small channels for the Dapur Saya offline queue (KIT-16), so no
 * third-party plugin is needed:
 * - `id.keluargamakan.app/device` `clock`: the boot count and
 *   `SystemClock.elapsedRealtime()`, a monotonic clock that counts deep
 *   sleep, so the age of a queued change does not depend on the phone's
 *   clock setting (lib/sync/device_clock.dart).
 * - `id.keluargamakan.app/connectivity`: true when a network with
 *   validated internet is available, false when it is lost, so the queue is
 *   sent when the connection returns (lib/sync/sync_signals.dart).
 * Nothing personal is read or sent.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "id.keluargamakan.app/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "clock" -> {
                    val boot = Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1)
                    result.success(
                        mapOf(
                            // Without a boot count the app uses its own
                            // per-run timeline instead.
                            "bootCount" to (if (boot >= 0) boot else null),
                            "elapsedRealtimeMs" to SystemClock.elapsedRealtime(),
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "id.keluargamakan.app/connectivity")
            .setStreamHandler(ConnectivityStream(applicationContext))
    }
}

private class ConnectivityStream(private val context: Context) : EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val manager = context.getSystemService(ConnectivityManager::class.java) ?: return
        val next = object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                val online = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                main.post { events.success(online) }
            }

            override fun onLost(network: Network) {
                main.post { events.success(false) }
            }
        }
        try {
            manager.registerDefaultNetworkCallback(next)
            callback = next
        } catch (e: RuntimeException) {
            // Too many callbacks or no permission: the backoff timer still retries.
        }
    }

    override fun onCancel(arguments: Any?) {
        val manager = context.getSystemService(ConnectivityManager::class.java)
        callback?.let { manager?.unregisterNetworkCallback(it) }
        callback = null
    }
}
