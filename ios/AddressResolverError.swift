//
//  BonjourError.swift
//  Pods
//
//  Created by Dawid Zawada on 06/11/2025.
//

enum AddressResolverError: Error {
    case timeout
    case extractionFailed
    
    var localizedDescription: String {
      switch self {
      case .timeout:
        return "Connection timed out"
      case .extractionFailed:
        return "Failed to extract IP and port information"
      }
    }
}
