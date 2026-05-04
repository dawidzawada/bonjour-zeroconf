//
//  LocalNetworkPermission.swift
//  Pods
//
//  Created by Dawid Zawada on 16/11/2025.
//
import NitroModules
import Network

class LocalNetworkPermission: HybridLocalNetworkPermissionSpec {
  internal var permissionListeners: [UUID: (Bool) -> Void] = [:]
  func requestPermission() throws -> Promise<Bool> {
    return Promise.async {
      if #available(iOS 14.0, *) {
        return await self.requestAuthorizationAsync()
      } else {
        return true
      }
    }
  }
  
  func listenForPermission(onChange: @escaping (Bool) -> Void) -> BonjourListener {
    let listenerId = UUID()
    self.permissionListeners[listenerId] = onChange
    
    return BonjourListener { [weak self] in
      self?.permissionListeners.removeValue(forKey: listenerId)
    }
  }

  @MainActor
  private func requestAuthorizationAsync() async -> Bool {
    let auth = LocalNetworkAuthorization()
    let granted = await auth.requestAuthorization()
    notifyPermissionListeners(with: granted)
    return granted
  }
}
