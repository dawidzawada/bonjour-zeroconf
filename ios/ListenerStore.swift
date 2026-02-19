//
//  ListenerStore.swift
//  Pods
//
//  Created by Dawid Zawada on 19/02/2026.
//
import Foundation

actor ListenerStore {
  private var scanResults: [UUID: ([ScanResult]) -> Void] = [:]
  private var scanState: [UUID: (Bool) -> Void] = [:]
  private var scanFail: [UUID: (BonjourFail) -> Void] = [:]

  func addScanResults(_ id: UUID, _ callback: @escaping ([ScanResult]) -> Void) {
    scanResults[id] = callback
  }

  func addScanState(_ id: UUID, _ callback: @escaping (Bool) -> Void) {
    scanState[id] = callback
  }

  func addScanFail(_ id: UUID, _ callback: @escaping (BonjourFail) -> Void) {
    scanFail[id] = callback
  }

  func remove(_ id: UUID) {
    scanResults.removeValue(forKey: id)
    scanState.removeValue(forKey: id)
    scanFail.removeValue(forKey: id)
  }

  func notifyScanResults(with results: [ScanResult]) {
    for listener in scanResults.values { listener(results) }
  }

  func notifyScanState(with isScanning: Bool) {
    for listener in scanState.values { listener(isScanning) }
  }

  func notifyScanFail(with fail: BonjourFail) {
    for listener in scanFail.values { listener(fail) }
  }
}
