//
//  Log+Exts.swift
//  
//
//  Created by Kien Nguyen on 01/07/22.
//

import Foundation

public extension Log {
    
    static let shared = Log()
    
    /// Convenience func to use `shared` instance
    static func d(_ items: Any...) {
        guard shared.isEnabled else { return } /// prevent unneccessary mapping
        /// `items` is Array, so it passed to `shared.d()` as first argument instead of varargs -> we have to map
        shared.d(items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func i(_ items: Any...) {
        guard shared.isEnabled else { return }
        shared.i(items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func w(_ items: Any...) {
        guard shared.isEnabled else { return }
        shared.w(items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to use `shared` instance
    static func e(_ items: Any...) {
        guard shared.isEnabled else { return }
        shared.e(items.map({ String(describing: $0) }).joined(separator: " "))
    }
    
    /// Convenience func to log with `.debug` level
    /// - Parameters:
    ///   - category: category
    ///   - items: items
    func d(_ items: Any...) {
        log(level: .debug, items: items)
    }
    
    /// Convenience func to log with `.info` level
    /// - Parameters:
    ///   - category: category
    ///   - items: items
    func i(_ items: Any...) {
        log(level: .info, items: items)
    }
    
    /// Convenience func to log with `.warning` level
    /// - Parameters:
    ///   - category: category
    ///   - items: items
    func w(_ items: Any...) {
        log(level: .warning, items: items)
    }
    
    /// Convenience func to log with `.error` level
    /// - Parameters:
    ///   - category: category
    ///   - items: items
    func e(_ items: Any...) {
        log(level: .error, items: items)
    }
    
    /// Put inside `deinit` to log an object deinitialization with `.debug` level
    /// - Parameter object: object
    func logDeinit(_ object: Any) {
        d("✅ \(String(describing: type(of: object))) deinit!")
    }
    
    /// Log `URLRequest` in  cURL format with `.debug` level
    /// - Parameters:
    ///   - request: request to log
    ///   - prefix: prefix to append before cURL string
    func logcURLRequest(_ request: URLRequest, withBody: Bool = true, prefix: String? = nil) {
        guard isEnabled else {
            return
        }
        
        if let prefix = prefix {
            d(prefix, request.generatecURL(withBody: withBody) ?? request.description)
        } else {
            d(request.generatecURL(withBody: withBody) ?? request.description)
        }
    }
}

private extension URLRequest {
    
    /**
     Returns a cURL command representation of this URL request.
     */
    func generatecURL(withBody: Bool = true) -> String? {
        guard let url = url, let method = httpMethod?.uppercased() else { return nil }
        var baseCommand = #"curl -L "\#(url.absoluteString)""#
        
        if method == "HEAD" {
            baseCommand += " --head"
        }
        
        var command = [baseCommand]
        
        if method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers {
                command.append("-H '\(key): \(value)'")
            }
        }
        
        if let data = httpBody {
            if withBody {
                if let body = String(data: data, encoding: .utf8) {
                    command.append("-d '\(body)'")
                } else {
                    command.append("-d '<body is non-string>'")
                }
            } else {
                command.append("-d '<body is ommited>'")
            }
        }
        
        return command.joined(separator: " \\\n\t")
    }
}
