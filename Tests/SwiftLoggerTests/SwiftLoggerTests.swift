import XCTest
@testable import SwiftLogger

final class SwiftLoggerTests: XCTestCase {
    func testExample() {
        LogManager.shared.fileConfig = .init(useSingleFile: true,
                                             linesToTriggerTruncate: 0,
                                             linesToKeepWhenTruncate: 0)
        
        let log = Log(queue: .main)
        log.enabledOutputs = [.file]
        
        var request = URLRequest(url: URL(string: "https://google.com/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def/abc/def")!)
        request.httpMethod = "GET"
        request.setValue("0000000000000000000001", forHTTPHeaderField: "Header-Field-1")
        request.setValue("0000000000000000000002", forHTTPHeaderField: "Header-Field-2")
        request.setValue("0000000000000000000003", forHTTPHeaderField: "Header-Field-3")
        request.setValue("0000000000000000000004", forHTTPHeaderField: "Header-Field-4")
        request.setValue("0000000000000000000005", forHTTPHeaderField: "Header-Field-5")
        request.setValue("0000000000000000000000000.0000000000000000000000000000000000000.00000000000000000000000000000000000.0000000000000000000000000000.000000000000000000000000000.000000000000000000000000000.0000000000000000000000000000003", forHTTPHeaderField: "Very-Long-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for i in (0...50000).reversed() {
            log.logcURLRequest(request, prefix: "#\(i)")
        }
        
        print(LogManager.shared.filePath)
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
