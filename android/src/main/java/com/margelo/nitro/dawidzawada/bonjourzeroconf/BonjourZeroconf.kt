package com.margelo.nitro.dawidzawada.bonjourzeroconf

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import com.facebook.proguard.annotations.DoNotStrip
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import com.margelo.nitro.NitroModules
import com.margelo.nitro.core.Promise
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

@DoNotStrip
class BonjourZeroconf : HybridBonjourZeroconfSpec() {

  companion object {
    internal const val TAG = "BonjourZeroconf"
    internal const val DEFAULT_RESOLVE_TIMEOUT_MS = 10_000L
  }

  @Volatile
  internal var _isScanning = false

  internal val scanStateListeners = ConcurrentHashMap<UUID, (Boolean) -> Unit>()
  internal val scanResultsListeners = ConcurrentHashMap<UUID, (Array<ScanResult>) -> Unit>()
  internal val scanFailListeners = ConcurrentHashMap<UUID, (BonjourFail) -> Unit>()

  internal var nsdManager: NsdManager? = null
  internal var currentDiscoveryListener: NsdManager.DiscoveryListener? = null
  internal val serviceCache = ConcurrentHashMap<String, ScanResult>()
  internal val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
  internal val resolveScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
  internal val legacyResolveMutex = Mutex()

  override val isScanning: Boolean
    get() = _isScanning

  override fun scan(type: String, domain: String, options: ScanOptions?) {
    if (_isScanning) {
      return
    }

    val context = NitroModules.applicationContext
      ?: throw IllegalStateException("Application context is not available.")

    if (nsdManager == null) {
      nsdManager = context.getSystemService(Context.NSD_SERVICE) as? NsdManager
        ?: throw IllegalStateException("NsdManager service is not available on this device.")
    }

    val resolveTimeout = options?.addressResolveTimeout?.toLong() ?: DEFAULT_RESOLVE_TIMEOUT_MS


    currentDiscoveryListener = createDiscoveryListener(resolveTimeout).also { listener ->
      try {
        Log.i(TAG, "Starting scan for type: $type")
        updateScanningState(true)
        nsdManager?.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
          ?: throw IllegalStateException("NsdManager is not initialized")
      } catch (e: Exception) {
        Log.e(TAG, "Failed to start discovery", e)
        updateScanningState(false)
        throw RuntimeException("Failed to start service discovery: ${e.message}", e)
      }
    }
  }

  override fun scanFor(
    time: Double,
    type: String,
    domain: String,
    options: ScanOptions?
  ): Promise<Array<ScanResult>> {
    return Promise.async {
      scan(type, domain, options)

      kotlinx.coroutines.delay((time * 1000).toLong())

      val results = serviceCache.values.toTypedArray()

      stop()

      results
    }
  }

  override fun stop() {
    resolveScope.coroutineContext.cancelChildren()

    currentDiscoveryListener?.let { listener ->
      try {
        nsdManager?.stopServiceDiscovery(listener)
        Log.i(TAG, "Stopped service discovery")
      } catch (e: Exception) {
        Log.e(TAG, "Error stopping discovery", e)
      }
    }

    currentDiscoveryListener = null
    serviceCache.clear()
  }

  override fun listenForScanResults(onResult: (Array<ScanResult>) -> Unit): BonjourListener {
    val id = UUID.randomUUID()
    scanResultsListeners[id] = onResult

    val currentResults = serviceCache.values.toTypedArray()
    if (currentResults.isNotEmpty()) {
      scope.launch(Dispatchers.Main) {
        try {
          onResult(currentResults)
        } catch (e: Exception) {
          Log.e(TAG, "Scan results listener error", e)
        }
      }
    }

    return BonjourListener {
      scanResultsListeners.remove(id)
    }
  }

  override fun listenForScanState(onChange: (Boolean) -> Unit): BonjourListener {
    val id = UUID.randomUUID()
    scanStateListeners[id] = onChange

    scope.launch(Dispatchers.Main) {
      try {
        onChange(_isScanning)
      } catch (e: Exception) {
        Log.e(TAG, "Scan state listener error", e)
      }
    }

    return BonjourListener {
      scanStateListeners.remove(id)
    }
  }

  override fun listenForScanFail(onFail: (BonjourFail) -> Unit): BonjourListener {
    val id = UUID.randomUUID()
    scanFailListeners[id] = onFail

    return BonjourListener {
      scanFailListeners.remove(id)
    }
  }

  private fun createDiscoveryListener(resolveTimeout: Long) = object : NsdManager.DiscoveryListener {

    override fun onDiscoveryStarted(serviceType: String) {
      Log.d(TAG, "Discovery started: $serviceType")
    }

    override fun onServiceFound(service: NsdServiceInfo) {
      val serviceKey = createServiceKey(service)
      Log.d(TAG, "Service found: ${service.serviceName} (key: $serviceKey)")

      if (serviceCache.containsKey(serviceKey)) {
        return
      }

      resolveScope.launch {
        try {
          resolveService(service, serviceKey, resolveTimeout)
        } catch (e: Exception) {
          Log.e(TAG, "Error resolving service: $serviceKey", e)
        }
      }
    }

    override fun onServiceLost(service: NsdServiceInfo) {
      val serviceKey = createServiceKey(service)
      Log.d(TAG, "Service lost: ${service.serviceName} (key: $serviceKey)")

      serviceCache.remove(serviceKey)?.let {
        notifyScanResultsListeners()
      }
    }

    override fun onDiscoveryStopped(serviceType: String) {
      Log.d(TAG, "Discovery stopped: $serviceType")
      updateScanningState(false)
    }

    override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
      Log.e(TAG, "Start discovery failed: $serviceType, error: $errorCode")
      notifyScanFailListeners(BonjourFail.DISCOVERY_FAILED)
      updateScanningState(false)
    }

    override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
      notifyScanFailListeners(BonjourFail.DISCOVERY_FAILED)
      Log.e(TAG, "Stop discovery failed: $serviceType, error: $errorCode")
    }
  }

  private fun createServiceKey(service: NsdServiceInfo): String {
    return "${service.serviceName}.${service.serviceType}"
  }
}
