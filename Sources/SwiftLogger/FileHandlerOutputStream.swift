//
//  FileHandlerOutputStream.swift
//
//  Created by Kien Nguyen on 7/2/20.
//

import Foundation

public class FileHandlerOutputStream: TextOutputStream {
    
    private let fileHandle: FileHandle
    private var currentLines: Int = 0
    private let highWatermark: Int
    
    public let filePath: URL
    public var maxLines: Int?

    public init(_ filePath: URL, maxLines: Int? = nil) throws {
        self.fileHandle = try FileHandle(forUpdating: filePath)
        self.filePath = filePath
        self.maxLines = maxLines
        self.highWatermark = (maxLines ?? 0) / 3
        
        if maxLines != nil {
            do {
                currentLines = try countLines(filePath: filePath)
            } catch {
                print(error)
            }
        }
    }

    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            fileHandle.write(data)
            if let newLine = "\n".data(using: .utf8) {
                fileHandle.write(newLine)
            }
            
            truncateLinesIfNeeded(data: data)
        }
    }
    
    private func truncateLinesIfNeeded(data: Data) {
        guard let maxLines = maxLines else {
            return
        }

        currentLines += countLines(data: data)
            
        if currentLines > maxLines + highWatermark {
            do {
                fileHandle.seek(toFileOffset: 0)
                let allData = fileHandle.readDataToEndOfFile()
                let newData = try truncatedLinesFromFile(data: allData,
                                                         linesToKeep: maxLines)
                fileHandle.truncateFile(atOffset: 0)
                fileHandle.write(newData)
                
                currentLines = maxLines
            } catch {
                print(error)
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

public extension FileHandlerOutputStream {
    func truncate(atOffset: UInt64 = 0) {
        fileHandle.truncateFile(atOffset: atOffset)
    }
    
    func synchronize() {
        fileHandle.synchronizeFile()
    }
    
    func seekToEnd() {
        fileHandle.seekToEndOfFile()
    }
    
    func close() {
        fileHandle.closeFile()
    }
}
