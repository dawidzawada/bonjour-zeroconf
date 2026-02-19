//
//  Logger.swift
//  Pods
//
//  Created by Dawid Zawada on 17/11/2025.
//
import Foundation

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

  private static func format(_ level: LogLevel, id: String?, message: String, function: String) -> String {
    let time = formatter.string(from: Date())
    let suffix = id.map { "(\($0)) " } ?? ""
    return "\(time): [\(level.rawValue)] \(suffix)🌐 BonjourZeroconf.\(function): \(message)"
  }

  /**
   * Log a message to the console with an optional scanner id suffix
   */
  @inlinable
  static func log(_ level: LogLevel,
                  id: String?,
                  message: String,
                  _ function: String = #function) {
    print(format(level, id: id, message: message, function: function))
  }

  /**
   * Log a message to the console
   */
  @inlinable
  static func log(_ level: LogLevel,
                  message: String,
                  _ function: String = #function) {
    print(format(level, id: nil, message: message, function: function))
  }
}
