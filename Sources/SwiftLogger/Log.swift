//
//  Log.swift
//
//  Created by Kien Nguyen on 6/30/20.
//

import Foundation
import os.log

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
    
    public enum Output {
        case osLog
        case file
        case websocket
    }
    
    /// Create a `Log` instance with a queue. `queue` should be serial,
    /// or else log lines could be in an incorrect order.
    /// Pass `nil` to use a default queue with `.utility` QoS.
    /// - Parameter queue: queue to execute all writing log actions
    /// - Parameter logFileExt: path to append to log path when writing to file
    public init(queue: DispatchQueue? = nil, logFileExt: String? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.ssss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = dateFormatter
        self.queue = queue ?? DispatchQueue(label: "swift-logger", qos: .utility)
        self.logManager = .init(extPath: logFileExt)
    }
    
    /// Global flag to enable/disable logging
    public var isEnabled: Bool = true
    
    /// Specific which outputs to be enabled. Defaults to `[.osLog, .file]`
    public var enabledOutputs: Set<Output> = [.osLog, .file]
    
    /// Websocket client to be used for `.websocket` output
    public var websocketClient: WebsocketClientType? {
        didSet {
            initializeWebsocketClient()
        }
    }
    
    public let logManager: LogManager
    
    private static let defaultOsLog: OSLog = OSLog(subsystem: subsystem, category: "default")
    
    private let dateFormatter: DateFormatter
    private let queue: DispatchQueue
    
    /// Log items
    /// - Parameters:
    ///   - category: category of this log
    ///   - level: log level
    ///   - items: items
    public func log(level: Level, items: [Any]) {
        
        guard isEnabled else { return }
        
        queue.async { [self] in
            let itemString = items.map { String(describing: $0) }.joined(separator: " ")
            logToOSLog(level: level, message: itemString)
            logToFile(level: level, message: itemString)
            logToWebsocket(level: level, message: itemString)
        }
    }
    
    public func updateLogManagerFileConfig(_ fileConfig: LogManager.FileConfig) {
        queue.async {
            self.logManager.fileConfig = fileConfig
        }
    }
    
    private func logToFile(level: Level, message: String) {
        if enabledOutputs.contains(.file) {
            let string = "\(dateFormatter.string(from: Date())) [\(level.name)]\(level.indicator) \(message)"
            logManager.write(string)
        }
    }
    
    private func logToOSLog(level: Level, message: String) {
        if enabledOutputs.contains(.osLog) {
            os_log("%{public}s%{public}s", log: Log.defaultOsLog, type: level.osLogLevel, level.indicator, message)
        }
    }
    
    private func logToWebsocket(level: Level, message: String) {
        guard enabledOutputs.contains(.websocket), let ws = websocketClient else { return }
        let string = "\(dateFormatter.string(from: Date())) [\(level.name)]\(level.indicator) \(message)"
        ws.send(message: string)
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
            return "🔴"
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
