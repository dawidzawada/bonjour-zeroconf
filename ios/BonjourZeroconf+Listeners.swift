//
//  BonjourZeroconf+Listeners.swift
//  Pods
//
//  Created by Dawid Zawada on 05/11/2025.
//

extension BonjourZeroconf {
  internal func notifyScanResultsListeners(with results: [ScanResult]) {
    Task { await listenerStore.notifyScanResults(with: results) }
  }

  internal func notifyScanStateListeners(with isScanningState: Bool) {
    Task { await listenerStore.notifyScanState(with: isScanningState) }
  }

  internal func notifyScanFailListeners(with fail: BonjourFail) {
    Task { await listenerStore.notifyScanFail(with: fail) }
  }
}
