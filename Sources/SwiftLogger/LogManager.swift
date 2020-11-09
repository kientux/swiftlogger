//
//  LogManager.swift
//  Sapo
//
//  Created by Kien Nguyen on 7/2/20.
//  Copyright © 2020 Sapo Technology JSC. All rights reserved.
//

import Foundation

public class LogManager {
    
    public struct CustomError: LocalizedError {
        init(message: String) {
            self.message = message
        }
        
        private let message: String
        
        public var errorDescription: String? {
            message
        }
    }
    
    private let directoryPath: String
    private let filePath: String
    
    public init(directoryPath: String) {
        self.directoryPath = directoryPath
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        
        let fileName = formatter.string(from: Date())
        self.filePath = (directoryPath as NSString).appendingPathComponent("\(fileName).txt")
    }
    
    public lazy var fileHandler: FileHandlerOutputStream? = {
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory at path \(directoryPath):", error)
                return nil
            }
        }
        
        if !FileManager.default.fileExists(atPath: filePath) {
            let success = FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            if !success {
                print("Error creating file at path \(filePath)")
                return nil
            }
        }
        
        let url = URL(fileURLWithPath: filePath)
        if let fileHandler = try? FileHandlerOutputStream(url) {
            fileHandler.seekToEnd()
            initialWrite(using: fileHandler)
            return fileHandler
        }
        
        return nil
    }()
    
    public func listContents() throws -> [URL] {
        let url = URL(fileURLWithPath: directoryPath, isDirectory: true)
        return try FileManager.default.contentsOfDirectory(at: url,
                                                           includingPropertiesForKeys: [.nameKey, .totalFileSizeKey],
                                                           options: [])
    }
    
    public func retrieveContents(ofLogNamed fileName: String) throws -> String? {
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        let fileUrl = URL(fileURLWithPath: filePath)
        return try String(contentsOf: fileUrl, encoding: .utf8)
    }
    
    public func deleteLog(named fileName: String) throws {
        if isCurrentlyLogged(into: fileName) {
            throw CustomError(message: "Cannot delete current log file. Use rotate instead.")
        }
        
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        let fileUrl = URL(fileURLWithPath: filePath)
        try FileManager.default.removeItem(at: fileUrl)
    }
    
    public func rotate() {
        fileHandler?.truncate()
        initialWrite(using: fileHandler)
    }
    
    public func synchronize() {
        fileHandler?.synchronize()
    }
    
    public func close() {
        closedWrite()
        fileHandler?.close()
    }
    
    public func isCurrentlyLogged(into fileName: String) -> Bool {
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        return filePath == self.filePath
    }
    
    private func closedWrite() {
        fileHandler?.write(
            """
            
            ----------
            File closed: \(Date())
            ----------
            """
        )
    }
    
    private func initialWrite(using fileHandler: FileHandlerOutputStream?) {
        guard let fileHandler = fileHandler else { return }
        let filePath = fileHandler.filePath
        fileHandler.write(
            """
            ----------
            File location: \(filePath)
            
            Timestamp: \(Date())
            ----------
            
            """
        )
    }
}

public extension LogManager {
    private static let defaultDirectoryPath: String? = {
        guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        return (path as NSString).appendingPathComponent("logs")
    }()
    
    convenience init() {
        self.init(directoryPath: LogManager.defaultDirectoryPath ?? "")
    }
    
    static let shared = LogManager()
}
