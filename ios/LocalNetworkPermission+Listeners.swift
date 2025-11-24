//
//  LocalNetworkPermission+Listeners.swift
//  Pods
//
//  Created by Dawid Zawada on 16/11/2025.
//

extension LocalNetworkPermission {
  internal func notifyPermissionListeners(with granted: Bool) {
    for listener in permissionListeners.values {
      listener(granted)
    }
  }
}
