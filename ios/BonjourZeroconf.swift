import NitroModules
import Foundation
import Network

class BonjourZeroconf: HybridBonjourZeroconfSpec {
  private var _browser: NWBrowser?
  private let serviceCache = ServiceCache()
  
  private let DEFAULT_RESOLVE_TIMEOUT = 10.0
  
  internal var scanResultsListeners: [UUID: ([ScanResult]) -> Void] = [:]
  internal var scanStateListeners: [UUID: (Bool) -> Void] = [:]
  internal var scanFailListeners: [UUID: (BonjourFail) -> Void] = [:]
  internal let networkQueue = DispatchQueue(label: "com.bonjour-zeroconf.network", qos: .userInitiated)
  
  var isScanning: Bool {
    return _isScanning
  }
  
  internal var _isScanning = false {
    didSet {
      notifyScanStateListeners(with: _isScanning)
    }
  }


  func scan(type: String, domain: String, options: ScanOptions?) {
      if _isScanning {
        Loggy.log(.warning, message: "Cannot start scanning, already scanning")
        return
      }
    
      let resolveTimeout = options?.addressResolveTimeout ?? DEFAULT_RESOLVE_TIMEOUT
    
      let browser = NWBrowser(for: .bonjour(type: type, domain: domain), using: .tcp)
      self._browser = browser
      self._isScanning = true
      
      browser.stateUpdateHandler = { [weak self] state in
          guard let self = self else { return }
          
          switch state {
          case .failed(let error):
              notifyScanFailListeners(with: BonjourFail.discoveryFailed)
              Loggy.log(.error, message: "Browser failed, reason: \(error.localizedDescription)")
              browser.cancel()
              self._isScanning = false
              
          case .ready:
              Loggy.log(.info, message: "Browser ready")
              
          case .cancelled:
              Loggy.log(.info, message: "Browser cancelled")
              self._isScanning = false
              
          default:
              break
          }
      }
      
      browser.browseResultsChangedHandler = { [weak self] results, changes in
          guard let self = self else { return }
          
          Loggy.log(.info, message: "Found \(results.count) service(s)")
          
          Task {
            await self.processChanges(changes, until: resolveTimeout)
          }
      }
    
      Loggy.log(.info, message: "Starting browser for service type: \(type)")
      browser.start(queue: networkQueue)
  }
  
  func listenForScanResults(onResult: @escaping ([ScanResult]) -> Void) -> BonjourListener {
    let listenerId = UUID()
    self.scanResultsListeners[listenerId] = onResult
    
    Task {
        let cachedResults = await serviceCache.getAll()
        onResult(cachedResults)
    }
    
    return BonjourListener { [weak self] in
      self?.scanResultsListeners.removeValue(forKey: listenerId)
    }
  }
  
  func listenForScanState(onChange: @escaping (Bool) -> Void) -> BonjourListener {
    let listenerId = UUID()
    self.scanStateListeners[listenerId] = onChange
    
    onChange(_isScanning)
    
    return BonjourListener { [weak self] in
      self?.scanStateListeners.removeValue(forKey: listenerId)
    }
  }
  
  func listenForScanFail(onFail: @escaping (BonjourFail) -> Void) -> BonjourListener {
    let listenerId = UUID()
    self.scanFailListeners[listenerId] = onFail
    
    return BonjourListener { [weak self] in
      self?.scanFailListeners.removeValue(forKey: listenerId)
    }
  }
  

  func stop() {
      if let browser = self._browser {
          browser.cancel()
      }
      
      self._isScanning = false
      Task {
          await serviceCache.clear()
      }
      Loggy.log(.info, message: "Stopped scanning")
  }
  
  /// Process all discovered services and resolve their IP addresses
  private func processChanges(_ changes: Set<NWBrowser.Result.Change>, until resolveTimeout: Double) async {
      var hasChanges = false
      
      var servicesToResolve: [(key: String, result: NWBrowser.Result, name: String)] = []
      
      for change in changes {
          switch change {
          case .added(let result):
              guard let key = serviceKey(for: result) else { continue }
              
              if await serviceCache.get(key) == nil {
                  guard case .service(let name, _, _, _) = result.endpoint else { continue }
                  Loggy.log(.info, message: "New service detected: \(name)")
                  servicesToResolve.append((key: key, result: result, name: name))
                  hasChanges = true
              } else {
                  Loggy.log(.debug, message: "Service already cached: \(key)")
              }
              
          case .removed(let result):
            guard let key = serviceKey(for: result) else { continue }
            
            if await serviceCache.remove(key) != nil {
                Loggy.log(.debug, message: "Service removed")
                hasChanges = true
            }
              
          case .changed(let _old, let new, let _flags):
            guard let key = serviceKey(for: new) else { continue }
            guard case .service(let name, _, _, _) = new.endpoint else { continue }
            
            Loggy.log(.debug, message: "Service changed: \(name)")
            servicesToResolve.append((key: key, result: new, name: name))
            hasChanges = true
            
          case .identical:
              break
              
          @unknown default:
              break
          }
      }
      
      // Resolve concurrently
      if !servicesToResolve.isEmpty {
          await withTaskGroup(of: (String, ScanResult?).self) { group in
              for service in servicesToResolve {
                  group.addTask {
                      let scanResult = await self.resolveService(
                          result: service.result,
                          name: service.name,
                          timeout: resolveTimeout
                      )
                      return (service.key, scanResult)
                  }
              }
              
              for await (key, scanResult) in group {
                  if let scanResult = scanResult {
                      await serviceCache.set(key, value: scanResult)
                      Loggy.log(.debug, message: "Resolved and cached service: \(scanResult.name)")
                  }
              }
          }
      }
      
      if hasChanges {
          let allResolvedServices = await serviceCache.getAll()
          notifyScanResultsListeners(with: allResolvedServices)
      }
  }
  
  private func serviceKey(for result: NWBrowser.Result) -> String? {
    guard case .service(let name, let type, let domain, _) = result.endpoint else {
      return nil
    }
    return "\(name).\(type).\(domain)"
  }
}
