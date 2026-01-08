//
//  BonjourZeroconf+AddressResolver.swift
//  Pods
//
//  Created by Dawid Zawada on 05/11/2025.
//
import Network

extension BonjourZeroconf {
  /// Resolve a service to get its IP address and port using async/await
  internal func resolveService(result: NWBrowser.Result, name: String, timeout: TimeInterval) async -> ScanResult? {
      let taskId = UUID()
      
      do {
          return try await withCheckedThrowingContinuation { continuation in
              let connection = NWConnection(to: result.endpoint, using: .tcp)
              
              resolveLock.lock()
              guard _isScanning else {
                  resolveLock.unlock()
                  continuation.resume(throwing: AddressResolverError.cancelled)
                  return
              }
              activeConnections[taskId] = connection
              resolveLock.unlock()
              
              final class ResumeBox { var hasResumed = false }
              let box = ResumeBox()
              
              let timeoutTask = DispatchWorkItem { [weak self] in
                  guard let self = self else { return }
                  guard !box.hasResumed else { return }
                  box.hasResumed = true
                  Loggy.log(.debug, message: "Timeout resolving \(name)")
                  continuation.resume(throwing: AddressResolverError.timeout)
                  self.cleanupResolve(connection: connection, taskId: taskId)
              }
              
              resolveLock.lock()
              activeTimeouts[taskId] = timeoutTask
              resolveLock.unlock()
              
              networkQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutTask)
              
              connection.stateUpdateHandler = { [weak self] state in
                  guard let self = self else { return }
                  switch state {
                  case .ready:
                      timeoutTask.cancel()
                      guard !box.hasResumed else { return }
                      box.hasResumed = true
                      
                      if let remoteEndpoint = connection.currentPath?.remoteEndpoint,
                         let scanResult = self.extractIPAndPort(from: remoteEndpoint, serviceName: name) {
                          continuation.resume(returning: scanResult)
                      } else {
                          continuation.resume(throwing: AddressResolverError.extractionFailed)
                      }
                      self.cleanupResolve(connection: connection, taskId: taskId)
                      
                  case .failed(let error):
                      timeoutTask.cancel()
                      guard !box.hasResumed else { return }
                      box.hasResumed = true
                      Loggy.log(.error, message: "Failed to resolve service \(name): \(error.localizedDescription)")
                      continuation.resume(throwing: error)
                      self.cleanupResolve(connection: connection, taskId: taskId)
                      
                  case .waiting(let error):
                      Loggy.log(.debug, message: "Connection waiting for \(name): \(error.localizedDescription)")
                      
                  case .cancelled:
                      break
                      
                  default:
                      break
                  }
              }
              
              connection.start(queue: networkQueue)
          }
      } catch let error as AddressResolverError {
          switch error {
          case .timeout:
              notifyScanFailListeners(with: BonjourFail.resolveFailed)
          case .extractionFailed:
              notifyScanFailListeners(with: BonjourFail.extractionFailed)
          case .cancelled:
              Loggy.log(.debug, message: "Scanning stopped, cancelling address resolution")
              break
          }
          return nil
      } catch {
          return nil
      }
  }
  
  /// Cancels ongoing address resolve process
  internal func cancelAddressResolving() {
      Loggy.log(.debug, message: "Cancelling Address Resolving")
      resolveLock.lock()
      activeTimeouts.values.forEach { $0.cancel() }
      activeTimeouts.removeAll()
      activeConnections.values.forEach { $0.cancel() }
      activeConnections.removeAll()
      resolveLock.unlock()
  }

  /// Cleans up after single resolve process
  private func cleanupResolve(connection: NWConnection, taskId: UUID) {
      connection.cancel()
      resolveLock.lock()
      activeConnections.removeValue(forKey: taskId)
      activeTimeouts.removeValue(forKey: taskId)
      resolveLock.unlock()
  }
  
  /// Extract IP address and port from an endpoint
  private func extractIPAndPort(from endpoint: NWEndpoint, serviceName: String) -> ScanResult? {
      switch endpoint {
      case .hostPort(let host, let port):
          var ipv4: String?
          var ipv6: String?
          var hostname: String?
          let portNumber = Int(port.rawValue)
          
          switch host {
          case .ipv4(let address):
              ipv4 = address.rawValue.map(String.init).joined(separator: ".")
              Loggy.log(.debug, message: "Resolved \(serviceName) -> IPv4: \(ipv4!), Port: \(portNumber)")
              
          case .ipv6(let address):
              let formatted = stride(from: 0, to: address.rawValue.count, by: 2).map { i in
                  String(format: "%02x%02x", address.rawValue[i], address.rawValue[i + 1])
              }.joined(separator: ":")
              
              if formatted.hasPrefix("fe80:") {
                if let interface = endpoint.interface?.name {
                      ipv6 = "\(formatted)%\(interface)"
                  } else {
                      ipv6 = "\(formatted)%en0"  // fallback
                  }
              } else {
                  ipv6 = formatted
              }
              Loggy.log(.debug, message: "Resolved \(serviceName) -> IPv6: \(ipv6!), Port: \(portNumber)")
              
          case .name(let name, _):
              hostname = name
              Loggy.log(.debug, message: "Resolved \(serviceName) -> Hostname: \(hostname ?? "nil"), Port: \(portNumber)")
              
          @unknown default:
              Loggy.log(.debug, message: "Unknown host type for \(serviceName)")
              return nil
          }
          
          return ScanResult(
              name: serviceName,
              ipv4: ipv4,
              ipv6: ipv6,
              hostname: hostname,
              port: Double(portNumber)
          )
          
      default:
          Loggy.log(.warning, message: "Unexpected endpoint format for \(serviceName)")
          return nil
      }
  }
}
