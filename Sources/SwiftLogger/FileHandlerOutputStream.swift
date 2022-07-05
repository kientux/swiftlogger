//
//  FileHandlerOutputStream.swift
//
//  Created by Kien Nguyen on 7/2/20.
//

import Foundation

private let TAG = "[FileHandlerOutputStream]"

class FileHandlerOutputStream: TextOutputStream {
    
    private let fileHandle: FileHandle
    
    private let linesToKeepWhenTruncate: Int
    private let linesToTriggerTruncate: Int
    private var currentLines: Int = 0
    
    public let filePath: URL
    
    init(filePath: URL,
         linesToTriggerTruncate: Int = 0,
         linesToKeepWhenTruncate: Int = 0) throws {
        self.fileHandle = try FileHandle(forUpdating: filePath)
        self.filePath = filePath
        
        assert(linesToTriggerTruncate == 0 || linesToTriggerTruncate > linesToKeepWhenTruncate,
               "linesToKeepWhenTruncate is smaller than or equal to linesToTriggerTruncate, " +
               "this will trigger truncate every time after log lines reached " +
               "linesToTriggerTruncate and drastically reduce logging performance.")
        
        self.linesToKeepWhenTruncate = linesToKeepWhenTruncate
        self.linesToTriggerTruncate = linesToTriggerTruncate
        
        if linesToTriggerTruncate > 0 {
            do {
                currentLines = try countLines(filePath: filePath)
            } catch {
                print(TAG, error)
            }
        }
    }
    
    func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            fileHandle.safeWrite(data)
            if let newLine = "\n".data(using: .utf8) {
                fileHandle.safeWrite(newLine)
            }
            
            truncateLinesIfNeeded(data: data)
        }
    }
    
    private func truncateLinesIfNeeded(data: Data) {
        guard linesToTriggerTruncate > 0 else {
            return
        }
        
        currentLines += countLines(data: data)
        
        if currentLines >= linesToTriggerTruncate {
            do {
                print(TAG, "Truncate log to \(linesToKeepWhenTruncate) lines from \(currentLines).")
                
                fileHandle.safeSeekToStart()
                let allData = fileHandle.safeReadToEnd() ?? Data()
                let truncatedData = try truncatedLinesFromFile(data: allData,
                                                               linesToKeep: linesToKeepWhenTruncate)
                fileHandle.safeTruncate(atOffset: 0)
                fileHandle.safeWrite(truncatedData)
                
                currentLines = linesToKeepWhenTruncate
            } catch {
                print(TAG, error)
            }
        }
    }
    
    private func countLines(filePath: URL) throws -> Int {
        countLines(data: try Data(contentsOf: filePath, options: .dataReadingMapped))
    }
    
    private func countLines(data: Data) -> Int {
        let nl = "\n".data(using: String.Encoding.utf8)!
        
        var lineNo = 1
        var pos = data.count - 1
        
        while pos >= 0, let range = data.range(of: nl, options: [.backwards], in: 0..<pos) {
            lineNo += 1
            pos = range.lowerBound
        }
        
        return lineNo
    }
    
    private func truncatedLinesFromFile(data: Data, linesToKeep numLines: Int) throws -> Data {
        let nl = "\n".data(using: String.Encoding.utf8)!
        
        var lineNo = 0
        var pos = data.count - 1
        
        while lineNo <= numLines {
            // Find next newline character:
            guard pos >= 0, let range = data.range(of: nl, options: [.backwards], in: 0..<pos) else {
                return data // File has less than `numLines` lines.
            }
            
            lineNo += 1
            pos = range.lowerBound
        }
        
        return data.subdata(in: pos..<data.count)
    }
}

/// Safe extensions to do FileHandle actions on iOS 13+/macOS 10.15+ when possible
/// because those new APIs throws error instead of ObjectiveC exceptions.
/// These extensions ignore throwed errors.
/// On prior OS versions, exceptions can still occur.
extension FileHandle {
    
    func safeReadToEnd() -> Data? {
        if #available(iOS 13.4, macOS 10.15.4, *) {
            do {
                return try readToEnd()
            } catch {
                print(TAG, "Failed to read to end:", error)
                return nil
            }
        } else {
            return readDataToEndOfFile()
        }
    }
    
    func safeWrite(_ data: Data) {
        if #available(iOS 13.4, macOS 10.15.4, *) {
            do {
                try write(contentsOf: data)
            } catch {
                print(TAG, "Failed to write data:", error)
            }
        } else {
            write(data)
        }
    }
    
    func safeTruncate(atOffset offset: UInt64) {
        if #available(iOS 13.0, macOS 10.15, *) {
            do {
                try truncate(atOffset: offset)
            } catch {
                print(TAG, "Failed to truncate:", error)
            }
        } else {
            truncateFile(atOffset: offset)
        }
    }
    
    func safeSeekTo(offset: UInt64) {
        if #available(iOS 13.0, macOS 10.15, *) {
            do {
                try seek(toOffset: offset)
            } catch {
                print(TAG, "Failed to seek to offset \(offset):", error)
            }
        } else {
            seek(toFileOffset: offset)
        }
    }
    
    func safeSeekToStart() {
        safeSeekTo(offset: 0)
    }
    
    func safeSeekToEnd() {
        if #available(iOS 13.4, macOS 10.15.4, *) {
            do {
                try seekToEnd()
            } catch {
                print(TAG, "Failed to seek to end:", error)
            }
        } else {
            seekToEndOfFile()
        }
    }
    
    func safeSync() {
        if #available(iOS 13.0, macOS 10.15, *) {
            do {
                try synchronize()
            } catch {
                print(TAG, "Failed to synchronize:", error)
            }
        } else {
            synchronizeFile()
        }
    }
    
    func safeClose() {
        if #available(iOS 13.0, macOS 10.15, *) {
            do {
                try close()
            } catch {
                print(TAG, "Failed to close:", error)
            }
        } else {
            closeFile()
        }
    }
}

extension FileHandlerOutputStream {
    func truncate(atOffset offset: UInt64 = 0) throws {
        fileHandle.safeTruncate(atOffset: offset)
    }
    
    func synchronize() throws {
        fileHandle.safeSync()
    }
    
    func seekTo(offset: UInt64) throws {
        fileHandle.safeSeekTo(offset: offset)
    }
    
    func seekToStart() throws {
        fileHandle.safeSeekToStart()
    }
    
    func seekToEnd() throws {
        fileHandle.safeSeekToEnd()
    }
    
    func close() throws {
        fileHandle.safeClose()
    }
}
