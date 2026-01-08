package com.margelo.nitro.dawidzawada.bonjourzeroconf

import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import androidx.annotation.RequiresApi
import com.margelo.nitro.dawidzawada.bonjourzeroconf.BonjourZeroconf.Companion.TAG
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.Executors

suspend fun BonjourZeroconf.resolveService(service: NsdServiceInfo, serviceKey: String, timeout: Long) {
  if (!_isScanning) return

  if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
    // New API (Android 14+)
    resolveServiceNew(service, serviceKey, timeout)
  } else {
    resolveServiceLegacy(service, serviceKey, timeout)
  }
}

@RequiresApi(34)
suspend fun BonjourZeroconf.resolveServiceNew(service: NsdServiceInfo, serviceKey: String, timeout: Long) {
  try {
    val resolved = withTimeoutOrNull(timeout) {
      suspendCancellableCoroutine { continuation ->
        val executor = Executors.newSingleThreadExecutor()

        val manager = nsdManager
        if (manager == null) {
          executor.shutdown()
          continuation.resume(null) {}
          return@suspendCancellableCoroutine
        }

        val callback = object : NsdManager.ServiceInfoCallback {
          fun unregisterCallback() {
            try {
              manager.unregisterServiceInfoCallback(this)
            } catch (e: Exception) {
              Log.e(TAG, "Error unregistering", e)
            }
          }

          override fun onServiceInfoCallbackRegistrationFailed(errorCode: Int) {
            Log.e(TAG, "Registration failed: ${service.serviceName}, error: $errorCode")
            notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
            unregisterCallback()
            continuation.resume(null) {}
          }

          override fun onServiceUpdated(serviceInfo: NsdServiceInfo) {
            Log.d(TAG, "Service updated: ${serviceInfo.serviceName}")
            unregisterCallback()

            if (!_isScanning) {
              continuation.resume(null) {}
              return
            }

            continuation.resume(serviceInfo) {}
          }

          override fun onServiceLost() {
            Log.d(TAG, "Service lost during resolution: ${service.serviceName}")
          }

          override fun onServiceInfoCallbackUnregistered() {
            Log.d(TAG, "Callback unregistered: ${service.serviceName}")
            executor.shutdown()
          }
        }

        try {
          manager.registerServiceInfoCallback(service, executor, callback)

          continuation.invokeOnCancellation {
            try {
              manager.unregisterServiceInfoCallback(callback)
            } catch (e: Exception) {
              Log.e(TAG, "Error unregistering on cancellation", e)
              executor.shutdown()
            }
          }
        } catch (e: Exception) {
          notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
          Log.e(TAG, "Exception registering callback", e)
          executor.shutdown()
          continuation.resume(null) {}
        }
      }
    }

    resolved?.let { serviceInfo ->
      extractScanResult(serviceInfo)?.let { scanResult ->
        serviceCache[serviceKey] = scanResult
        notifyScanResultsListeners()
      }
    } ?: Log.w(TAG, "Failed to resolve service: $serviceKey")

  } catch (e: Exception) {
    notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
    Log.e(TAG, "Error during service resolution", e)
  }
}

@Suppress("DEPRECATION")
suspend fun BonjourZeroconf.resolveServiceLegacy(service: NsdServiceInfo, serviceKey: String, timeout: Long) {
  try {
    val resolved = legacyResolveMutex.withLock {
      withTimeoutOrNull(timeout) {
        suspendCancellableCoroutine { continuation ->
          val resolveListener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
              Log.e(TAG, "Resolve failed: ${serviceInfo.serviceName}, error: $errorCode")

              notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
              continuation.resume(null) {}
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
              Log.d(TAG, "Service resolved: ${serviceInfo.serviceName}")

              if (!_isScanning) {
                continuation.resume(null) {}
                return
              }

              continuation.resume(serviceInfo) {}
            }
          }

          try {
            val manager = nsdManager
            if (manager == null) {
              continuation.resume(null) {}
              return@suspendCancellableCoroutine
            }

            manager.resolveService(service, resolveListener)
          } catch (e: Exception) {
            notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
            Log.e(TAG, "Exception resolving service", e)
            continuation.resume(null) {}
          }
        }
      }
    }

    resolved?.let { serviceInfo ->
      extractScanResult(serviceInfo)?.let { scanResult ->
        serviceCache[serviceKey] = scanResult
        notifyScanResultsListeners()
      }
    } ?: Log.w(TAG, "Failed to resolve service: $serviceKey")

  } catch (e: Exception) {
    Log.e(TAG, "Error during service resolution", e)
  }
}

private fun BonjourZeroconf.extractScanResult(serviceInfo: NsdServiceInfo): ScanResult? {
  return try {
    val host = serviceInfo.host ?: return null
    val port = serviceInfo.port

    val (ipv4, ipv6) = when {
      host.address.size == 4 -> host.hostAddress to null
      host.address.size == 16 -> null to formatIPv6Address(host.address)
      else -> null to null
    }

    ScanResult(
      name = serviceInfo.serviceName,
      ipv4 = ipv4,
      ipv6 = ipv6,
      hostname = host.hostName,
      port = port.toDouble()
    )
  } catch (e: Exception) {
    notifyScanFailListeners(BonjourFail.EXTRACTION_FAILED)
    Log.e(TAG, "Failed to extract scan result", e)
    null
  }
}

private fun formatIPv6Address(bytes: ByteArray): String {
  require(bytes.size == 16) { "IPv6 address must be 16 bytes" }

  return (0 until 16 step 2).joinToString(":") { i ->
    val segment = ((bytes[i].toInt() and 0xFF) shl 8) or (bytes[i + 1].toInt() and 0xFF)
    segment.toString(16)
  }
}
