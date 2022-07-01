import XCTest
@testable import SwiftLogger

final class SwiftLoggerTests: XCTestCase {
    func testExample() {
        LogManager.shared.fileConfig = .init(useSingleFile: true,
                                             linesToTriggerTruncate: 20000,
                                             linesToKeepWhenTruncate: 10000)
        
        let log = Log(queue: .main)
        log.enabledOutputs = [.file]
        
        var request = URLRequest(url: URL(string: "https://google.com")!)
        request.httpMethod = "GET"
        request.setValue("001", forHTTPHeaderField: "Header-Field-1")
        request.setValue("002", forHTTPHeaderField: "Header-Field-2")
        request.setValue("003", forHTTPHeaderField: "Header-Field-3")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for i in (0...30000).reversed() {
            log.logcURLRequest(request, prefix: "#\(i)")
        }
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
