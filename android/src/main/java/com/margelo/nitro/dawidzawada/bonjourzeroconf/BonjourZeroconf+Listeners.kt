package com.margelo.nitro.dawidzawada.bonjourzeroconf

import android.util.Log
import com.margelo.nitro.dawidzawada.bonjourzeroconf.BonjourZeroconf.Companion.TAG
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

fun BonjourZeroconf.notifyScanResultsListeners() {
  val results = serviceCache.values.toTypedArray()
  scope.launch(Dispatchers.Main) {
    scanResultsListeners.values.forEach { listener ->
      try {
        listener(results)
      } catch (e: Exception) {
        Log.e(TAG, "Error notifying scan results listener", e)
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
        Log.e(TAG, "Error notifying scan state listener", e)
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
        Log.e(TAG, "Error notifying scan fail listener", e)
      }
    }
  }
}
