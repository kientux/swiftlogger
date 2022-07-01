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
    
    func logDeinit(_ object: Any) {
        d("✅ \(String(describing: type(of: object))) deinit!")
    }
    
    func logcURLRequest(_ request: URLRequest, prefix: String? = nil) {
        guard isEnabled else {
            return
        }
        
        if let prefix = prefix {
            d(category: .network, prefix, request.curlString ?? "")
        } else {
            d(category: .network, request.curlString ?? "")
        }
    }
}

private extension URLRequest {
    
    /**
     Returns a cURL command representation of this URL request.
     */
    var curlString: String? {
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
        
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        
        return command.joined(separator: " \\\n\t")
    }
}