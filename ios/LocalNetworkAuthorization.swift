//
//  LocalNetworkAuthorization.swift
//  Pods
//
//  Created by Dawid Zawada on 16/11/2025.
//
import Foundation
import Network

// This code is based on https://stackoverflow.com/a/67758105/2618437
// And: https://github.com/neurio/react-native-local-network-permission
// https://gist.github.com/doozMen/0b5fc54c765bccb7c13792caa4eaa51c
@MainActor
public class LocalNetworkAuthorization: NSObject {
    private var browser: NWBrowser?
    private var netService: NetService?
    private var completion: ((Bool) -> Void)?

    deinit {
        netService?.delegate = nil
        netService?.stop()
        browser?.cancel()
    }

    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            start { continuation.resume(returning: $0) }
        }
    }

    private func start(completion: @escaping (Bool) -> Void) {
        self.completion = completion

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { [weak self] newState in
            guard case let .waiting(error) = newState else { return }
            guard let self else { return }
            Loggy.log(.warning, message: "Local network permission has been denied: \(error)")
            Task { @MainActor [self] in self.finish(granted: false) }
        }

        netService = NetService(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
        netService?.schedule(in: .main, forMode: .common)
        netService?.delegate = self
        browser.start(queue: .main)
        netService?.publish()
    }

    private func finish(granted: Bool) {
        let cb = completion
        reset()
        cb?(granted)
    }

    private func reset() {
        browser?.cancel()
        browser = nil
        netService?.delegate = nil
        netService?.stop()
        netService = nil
        completion = nil
    }
}

// @preconcurrency suppresses the Swift 6 isolation warning:
// netService is scheduled on main run loop
// so MainActor isolation is guaranteed at runtime even though the ObjC protocol
// doesn't express it statically.
extension LocalNetworkAuthorization: @preconcurrency NetServiceDelegate {
    public func netServiceDidPublish(_ sender: NetService) {
        Loggy.log(.info, message: "Local Network permission granted")
        finish(granted: true)
    }
}
