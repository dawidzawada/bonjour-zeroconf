package com.margelo.nitro.dawidzawada.bonjourzeroconf

import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import androidx.annotation.RequiresApi
import com.margelo.nitro.dawidzawada.bonjourzeroconf.BonjourZeroconf.Companion.legacyResolveMutex
import com.margelo.nitro.dawidzawada.bonjourzeroconf.BonjourZeroconf.Companion.loggy
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull
import java.net.Inet6Address
import java.net.NetworkInterface
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
              loggy.e("Error unregistering", id, e)
            }
          }

          override fun onServiceInfoCallbackRegistrationFailed(errorCode: Int) {
            loggy.e("Registration failed: ${service.serviceName}, error: $errorCode", id)
            notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
            unregisterCallback()
            if (continuation.isActive) continuation.resume(null) {}
          }

          override fun onServiceUpdated(serviceInfo: NsdServiceInfo) {
            loggy.d("Service updated: ${serviceInfo.serviceName}", id)
            unregisterCallback()

            if (!continuation.isActive) return

            if (!_isScanning) {
              continuation.resume(null) {}
              return
            }

            continuation.resume(serviceInfo) {}
          }

          override fun onServiceLost() {
            loggy.d("Service lost during resolution: ${service.serviceName}", id)
          }

          override fun onServiceInfoCallbackUnregistered() {
            loggy.d("Callback unregistered: ${service.serviceName}", id)
            executor.shutdown()
          }
        }

        try {
          manager.registerServiceInfoCallback(service, executor, callback)

          continuation.invokeOnCancellation {
            try {
              manager.unregisterServiceInfoCallback(callback)
            } catch (e: Exception) {
              loggy.e("Error unregistering on cancellation", id, e)
              executor.shutdown()
            }
          }
        } catch (e: Exception) {
          notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
          loggy.e("Exception registering callback", id, e)
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
    } ?: loggy.w("Failed to resolve service: $serviceKey", id)

  } catch (e: Exception) {
    notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
    loggy.e("Error during service resolution", id, e)
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
              loggy.e("Resolve failed: ${serviceInfo.serviceName}, error: $errorCode", id)

              notifyScanFailListeners(BonjourFail.RESOLVE_FAILED)
              continuation.resume(null) {}
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
              loggy.d("Service resolved: ${serviceInfo.serviceName}", id)

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
            loggy.e("Exception resolving service", id, e)
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
    } ?: loggy.w("Failed to resolve service: $serviceKey", id)

  } catch (e: Exception) {
    loggy.e("Error during service resolution", id, e)
  }
}

private fun BonjourZeroconf.extractScanResult(serviceInfo: NsdServiceInfo): ScanResult? {
  return try {
    val host = serviceInfo.host ?: return null
    val port = serviceInfo.port

    val (ipv4, ipv6) = when {
      host.address.size == 4 -> host.hostAddress to null
      host.address.size == 16 -> null to formatIPv6Address(host.address, host as? Inet6Address)
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
    loggy.e("Failed to extract scan result", id, e)
    null
  }
}

private fun formatIPv6Address(bytes: ByteArray, inet6Address: Inet6Address? = null): String {
  require(bytes.size == 16) { "IPv6 address must be 16 bytes" }

  val formatted = (0 until 16 step 2).joinToString(":") { i ->
    val segment = ((bytes[i].toInt() and 0xFF) shl 8) or (bytes[i + 1].toInt() and 0xFF)
    segment.toString(16)
  }

  if (formatted.startsWith("fe80:") && inet6Address != null) {
    val interfaceName = inet6Address.scopedInterface?.name
      ?: NetworkInterface.getByIndex(inet6Address.scopeId)?.name
    if (interfaceName != null) {
      return "$formatted%$interfaceName"
    }
  }

  return formatted
}
