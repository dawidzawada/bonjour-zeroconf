//
//  Logger.swift
//  Pods
//
//  Created by Dawid Zawada on 17/11/2025.
//
enum LogLevel: String {
  case debug
  case info
  case warning
  case error
}

enum Loggy {
  static var staticFormatter: DateFormatter?
  static var formatter: DateFormatter {
    guard let staticFormatter else {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      self.staticFormatter = formatter
      return formatter
    }
    return staticFormatter
  }

  /**
   * Log a message to the console`
   */
  @inlinable
  static func log(_ level: LogLevel,
                  message: String,
                  _ function: String = #function) {
    let now = Date()
    let time = formatter.string(from: now)
    print("\(time): [\(level.rawValue)] 🌐 BonjourZeroconf.\(function): \(message)")
  }
}
