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
      do {
          return try await withCheckedThrowingContinuation { continuation in
              let connection = NWConnection(to: result.endpoint, using: .tcp)
              
              final class ResumeBox {
                  var hasResumed = false
              }
              let box = ResumeBox()
              
              let timeoutTask = DispatchWorkItem {
                  guard !box.hasResumed else { return }
                  box.hasResumed = true
                  Loggy.log(.debug, message: "Timeout resolving \(name)")
                  continuation.resume(throwing: AddressResolverError.timeout)
                  connection.cancel()
              }
              networkQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutTask)
              
              connection.stateUpdateHandler = { [weak self] state in
                  switch state {
                  case .ready:
                      timeoutTask.cancel()
                      guard !box.hasResumed else { return }
                      box.hasResumed = true
                      
                      if let remoteEndpoint = connection.currentPath?.remoteEndpoint,
                         let scanResult = self?.extractIPAndPort(from: remoteEndpoint, serviceName: name) {
                          continuation.resume(returning: scanResult)
                      } else {
                          continuation.resume(throwing: AddressResolverError.extractionFailed)
                      }
                      connection.cancel()
                      
                  case .failed(let error):
                      timeoutTask.cancel()
                      guard !box.hasResumed else { return }
                      box.hasResumed = true
                      Loggy.log(.error, message: "Failed to resolve service \(name): \(error.localizedDescription)")
                      continuation.resume(throwing: error)
                      connection.cancel()
                      
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
          break;
        case .extractionFailed:
            notifyScanFailListeners(with: BonjourFail.extractionFailed)
          break;
        }
        return nil
    } catch {
        return nil
    }
  }
  
  /// Extract IP address and port from an endpoint
  internal func extractIPAndPort(from endpoint: NWEndpoint, serviceName: String) -> ScanResult? {
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
