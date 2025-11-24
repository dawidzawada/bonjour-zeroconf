//
//  BonjourZeroconf+Listeners.swift
//  Pods
//
//  Created by Dawid Zawada on 05/11/2025.
//

extension BonjourZeroconf {
  internal func notifyScanResultsListeners(with results: [ScanResult]) {
    for listener in scanResultsListeners.values {
      listener(results)
    }
  }
  
  internal func notifyScanStateListeners(with isScanningState: Bool) {
    for listener in scanStateListeners.values {
      listener(isScanningState)
    }
  }
  
  internal func notifyScanFailListeners(with fail: BonjourFail) {
    for listener in scanFailListeners.values {
      listener(fail)
    }
  }
}
