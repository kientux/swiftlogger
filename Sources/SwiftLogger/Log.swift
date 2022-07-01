//
//  Log.swift
//
//  Created by Kien Nguyen on 6/30/20.
//

import Foundation
import os

private let subsystem: String = "swift-logger"

public protocol WebsocketClientType {
    func send(message: String)
    func connect()
    func disconnect()
}

public class Log {
    public enum Level: String {
        case debug
        case info
        case warning
        case error
    }
    
    public enum Category: String {
        case `default`
        case network
    }
    
    public enum Output {
        case osLog
        case file
        case websocket
    }
    
    public init(queue: DispatchQueue? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = dateFormatter
        self.queue = queue ?? DispatchQueue(label: "swift-logger", qos: .utility)
    }
    
    public var isEnabled: Bool = true
    public var enabledOutputs: Set<Output> = [.osLog, .file]
    public var maxFileLogLines: Int?
    
    public var websocketClient: WebsocketClientType? {
        didSet {
            enabledOutputs.insert(.websocket)
            initializeWebsocketClient()
        }
    }
    
    private static let `default`: OSLog = OSLog(subsystem: subsystem, category: Category.default.rawValue)
    private static let network: OSLog = OSLog(subsystem: subsystem, category: Category.network.rawValue)
    
    private let dateFormatter: DateFormatter
    private let queue: DispatchQueue
    
    public func log(category: Category = .default,
                    level: Level,
                    items: [Any]) {
        
        guard isEnabled else { return }
        
        queue.async { [self] in
            let itemString = items.map { String(describing: $0) }.joined(separator: " ")
            logToOSLog(category: category, level: level, message: itemString)
            logToFile(level: level, category: category, message: itemString)
            logToWebsocket(category: category, level: level, message: itemString)
        }
    }
    
    private func logToFile(level: Level, category: Category = .default, message: String) {
        if enabledOutputs.contains(.file), let output = LogManager.shared.fileHandler {
            let string = dateFormatter.string(from: Date()) + "[\(level.name)]\(level.indicator)" + message
            output.write(string)
        }
    }
    
    private func logToOSLog(category: Category, level: Level, message: String) {
        if enabledOutputs.contains(.osLog) {
            os_log("%{public}s%{public}s", log: osLog(for: category), type: level.osLogLevel, level.indicator, message)
        }
    }
    
    private func logToWebsocket(category: Category, level: Level, message: String) {
        guard enabledOutputs.contains(.websocket), let ws = websocketClient else { return }
        let string = dateFormatter.string(from: Date()) + "[\(level.name)]\(level.indicator)" + message
        ws.send(message: string)
    }
    
    private func osLog(for category: Category) -> OSLog {
        switch category {
        case .network:
            return Log.network
        case .default:
            return Log.default
        }
    }
    
    private func initializeWebsocketClient() {
        guard let ws = websocketClient else {
            return
        }
        
        ws.connect()
    }
    
    deinit {
        websocketClient?.disconnect()
    }
}

extension Log.Level {
    var indicator: String {
        switch self {
        case .debug:
            return ""
        case .info:
            return ""
        case .warning:
            return "⚠️"
        case .error:
            return "‼️"
        }
    }
    
    var name: String {
        rawValue.uppercased()
    }
    
    var osLogLevel: OSLogType {
        switch self {
        case .debug, .info, .warning:
            return .default
        case .error:
            return .error
        }
    }
}

public extension Log {
    
    static let shared = Log()
    
    /// Convenience func to use `shared` instance
    static func d(category: Category = .default, _ items: Any...) {
        guard shared.isEnabled else { return } /// prevent unneccessary mapping
        /// `items` is Array, so it passed to `shared.d()` as first argument instead of varargs -> we have to map
        shared.d(category: category, items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func i(category: Category = .default, _ items: Any...) {
        guard shared.isEnabled else { return }
        shared.i(category: category, items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func w(category: Category = .default, _ items: Any...) {
        guard shared.isEnabled else { return }
        shared.w(category: category, items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func e(category: Category = .default, _ items: Any...) {
        guard shared.isEnabled else { return }
        shared.e(category: category, items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    func d(category: Category = .default, _ items: Any...) {
        log(category: category, level: .debug, items: items)
    }
    
    func i(category: Category = .default, _ items: Any...) {
        log(category: category, level: .info, items: items)
    }
    
    func w(category: Category = .default, _ items: Any...) {
        log(category: category, level: .warning, items: items)
    }
    
    func e(category: Category = .default, _ items: Any...) {
        log(category: category, level: .error, items: items)
    }
    
    static func logDeinit(_ object: Any) {
        Log.d("✅ \(String(describing: type(of: object))) deinit!")
    }
    
    func logCache(_ name: String) {
        d(category: .network, "✅ Get cached \(name).")
    }
}
