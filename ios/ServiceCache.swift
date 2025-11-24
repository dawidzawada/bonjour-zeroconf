//
//  ServiceCache.swift
//  Pods
//
//  Created by Dawid Zawada on 05/11/2025.
//

actor ServiceCache {
    private var cache: [String: ScanResult] = [:]
    
    func get(_ key: String) -> ScanResult? {
        return cache[key]
    }
    
    func set(_ key: String, value: ScanResult) {
        cache[key] = value
    }
    
    func remove(_ key: String) -> ScanResult? {
        return cache.removeValue(forKey: key)
    }
    
    func getAll() -> [ScanResult] {
        return Array(cache.values)
    }
    
    func clear() {
        cache.removeAll()
    }
}
