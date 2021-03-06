//
//  LogManager.swift
//
//  Created by Kien Nguyen on 7/2/20.
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
    
    public struct FileConfig {
        /// Use single log file or split log files by date
        public let useSingleFile: Bool
        
        /// Number of lines where log file getting truncated (high watermark)
        public let linesToTriggerTruncate: Int
        
        /// Number of lines to keep when truncation is triggered (low watermark)
        public let linesToKeepWhenTruncate: Int
        
        public init(useSingleFile: Bool = false,
                    linesToTriggerTruncate: Int = 0,
                    linesToKeepWhenTruncate: Int = 0) {
            self.useSingleFile = useSingleFile
            self.linesToTriggerTruncate = linesToTriggerTruncate
            self.linesToKeepWhenTruncate = linesToKeepWhenTruncate
        }
    }
    
    private let directoryPath: String
    private(set) var filePath: String = ""
    
    public internal(set) var fileConfig: FileConfig = .init() {
        didSet {
            reloadFileHandler()
        }
    }
    
    public init(directoryPath: String) {
        self.directoryPath = directoryPath
        self.filePath = generateFilePath()
        self.fileHandler = createFileHandler()
    }
    
    private var fileHandler: FileHandlerOutputStream?
    
    public struct FileMetadata {
        public var name: String
        public var size: Int
        public var path: URL
        public var isCurrent: Bool
    }
    
    /// Get all log files path with some useful properties
    /// - Returns: list `URL` to log file
    public func listContents() throws -> [URL] {
        let url = URL(fileURLWithPath: directoryPath, isDirectory: true)
        return try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .nameKey,
                .totalFileSizeKey,
                .creationDateKey,
                .contentModificationDateKey,
            ],
            options: []
        )
    }
    
    /// Get all log files with metadatas
    /// - Returns: list metadata
    public func listContentMetadatas() throws -> [FileMetadata] {
        let urls = try listContents()
        var metadatas: [FileMetadata] = []
        
        for url in urls {
            let values = try url.resourceValues(forKeys: [.nameKey, .fileSizeKey])
            let metadata = FileMetadata(name: values.name ?? "",
                                        size: values.fileSize ?? 0,
                                        path: url,
                                        isCurrent: isCurrentlyLogged(into: values.name ?? ""))
            metadatas.append(metadata)
        }
        
        return metadatas
    }
    
    /// Retrieve content of a log file by name
    /// - Parameter fileName: log file name, from `listContents()` or `listContentMetadatas()`
    /// - Returns: content of log file
    public func retrieveContents(ofLogNamed fileName: String) throws -> String? {
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        let fileUrl = URL(fileURLWithPath: filePath)
        return try String(contentsOf: fileUrl, encoding: .utf8)
    }
    
    /// Delete log file by name
    /// - Parameter fileName: log file name, from `listContents()` or `listContentMetadatas()`
    public func deleteLog(named fileName: String) throws {
        if isCurrentlyLogged(into: fileName) {
            throw CustomError(message: "Cannot delete current log file. Use rotate instead.")
        }
        
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        let fileUrl = URL(fileURLWithPath: filePath)
        try FileManager.default.removeItem(at: fileUrl)
    }
    
    /// Rotate (clear) current log file
    public func rotate() {
        fileHandler?.truncate(atOffset: 0)
        initialWrite(using: fileHandler, appendOnly: false)
    }
    
    /// Manually write all in-mem file data to storage
    public func synchronize() {
        fileHandler?.synchronize()
    }
    
    /// Close file handler
    public func close() {
        closedWrite()
        fileHandler?.close()
    }
    
    /// Check if a log file is current log
    /// - Parameter fileName: fileName
    /// - Returns: `true` if currently logging into `fileName`
    public func isCurrentlyLogged(into fileName: String) -> Bool {
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)
        return filePath == self.filePath
    }
    
    func write(_ s: String) {
        fileHandler?.write(s)
    }
    
    private func reloadFileHandler() {
        filePath = generateFilePath()
        
        fileHandler?.close()
        fileHandler = createFileHandler()
    }
    
    private func createFileHandler() -> FileHandlerOutputStream? {
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory at path \(directoryPath):", error)
                return nil
            }
        }
        
        var isFileExist: Bool = true
        
        if !FileManager.default.fileExists(atPath: filePath) {
            isFileExist = false
            
            let success = FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            if !success {
                print("Error creating file at path \(filePath)")
                return nil
            }
        }
        
        let url = URL(fileURLWithPath: filePath)
        if let fileHandler = try? FileHandlerOutputStream(
            filePath: url,
            linesToTriggerTruncate: fileConfig.linesToTriggerTruncate,
            linesToKeepWhenTruncate: fileConfig.linesToKeepWhenTruncate
        ) {
            fileHandler.seekToEnd()
            initialWrite(using: fileHandler, appendOnly: isFileExist)
            return fileHandler
        }
        
        return nil
    }
    
    private func generateFilePath() -> String {
        if fileConfig.useSingleFile {
            return (directoryPath as NSString).appendingPathComponent("swiftlog.txt")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        
        let date = formatter.string(from: Date())
        
        return (directoryPath as NSString).appendingPathComponent("\(date).txt")
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
    
    private func initialWrite(using fileHandler: FileHandlerOutputStream?,
                              appendOnly: Bool) {
        guard let fileHandler = fileHandler else { return }
        let filePath = fileHandler.filePath
        fileHandler.write(
            appendOnly
            ?
            """
            ----------
            File appended: \(Date())
            ----------
            
            """
            :
            """
            ----------
            File open: \(filePath)
            Timestamp: \(Date())
            ----------
            
            """
        )
    }
}

extension LogManager {
    private static func defaultDirectoryPath(extPath: String?) -> String? {
        guard var path = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask, true).first else {
            return nil
        }
        
        path = (path as NSString).appendingPathComponent("logs")
        
        if let extPath = extPath {
            path = (path as NSString).appendingPathComponent(extPath)
        }
        
        return path
    }
    
    convenience init() {
        self.init(directoryPath: LogManager.defaultDirectoryPath(extPath: nil) ?? "")
    }
    
    convenience init(extPath: String?) {
        self.init(directoryPath: LogManager.defaultDirectoryPath(extPath: extPath) ?? "")
    }
}
