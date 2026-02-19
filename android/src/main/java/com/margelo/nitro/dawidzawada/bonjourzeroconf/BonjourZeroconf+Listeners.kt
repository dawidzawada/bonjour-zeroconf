package com.margelo.nitro.dawidzawada.bonjourzeroconf

import com.margelo.nitro.dawidzawada.bonjourzeroconf.BonjourZeroconf.Companion.loggy
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

fun BonjourZeroconf.notifyScanResultsListeners() {
  val results = serviceCache.values.toTypedArray()
  scope.launch(Dispatchers.Main) {
    scanResultsListeners.values.forEach { listener ->
      try {
        listener(results)
      } catch (e: Exception) {
        loggy.e("Error notifying scan results listener", id, e)
      }
    }
  }
}

fun BonjourZeroconf.updateScanningState(newState: Boolean) {
  _isScanning = newState
  scope.launch(Dispatchers.Main) {
    scanStateListeners.values.forEach { listener ->
      try {
        listener(newState)
      } catch (e: Exception) {
        loggy.e("Error notifying scan state listener", id, e)
      }
    }
  }
}


fun BonjourZeroconf.notifyScanFailListeners(fail: BonjourFail) {
  scope.launch(Dispatchers.Main) {
    scanFailListeners.values.forEach { listener ->
      try {
        listener(fail)
      } catch (e: Exception) {
        loggy.e("Error notifying scan fail listener", id, e)
      }
    }
  }
}
