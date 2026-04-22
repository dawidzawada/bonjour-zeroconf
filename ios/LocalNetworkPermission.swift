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
  private var pendingAuthorization: LocalNetworkAuthorization?
  
  func requestPermission() throws -> Promise<Bool> {
    return Promise.async {
      if #available(iOS 14.0, *) {
        return try await self.requestAuthorizationAsync()
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

  private func requestAuthorizationAsync() async throws -> Bool {
    return await withCheckedContinuation { continuation in
      let authorizationInstance = LocalNetworkAuthorization()
      self.pendingAuthorization = authorizationInstance
      authorizationInstance.requestAuthorization { [weak self] granted in
        self?.notifyPermissionListeners(with: granted)
        self?.pendingAuthorization = nil
        continuation.resume(returning: granted)
      }
    }
  }
}
