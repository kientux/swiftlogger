import XCTest
@testable import SwiftLogger

final class SwiftLoggerTests: XCTestCase {
    func testExample() {
        LogManager.shared.singleFile = true
        LogManager.shared.maxLinesWhenTruncate = 20000
        
        let log = Log(queue: .main)
        log.enabledOutputs = [.file]
        
        for _ in 0...50000 {
            log.d(
                """
                let metadatas = try? LogManager.shared.listContentMetadatas()
                let metadatas = try? LogManager.shared.listContentMetadatas()
                """
            )
        }
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
