import XCTest
@testable import SwiftLogger

final class SwiftLoggerTests: XCTestCase {
    func testExample() {
        LogManager.shared.fileConfig = .init(useSingleFile: true,
                                             linesToTriggerTruncate: 0,
                                             linesToKeepWhenTruncate: 0)
        
        let log = Log(queue: .main)
        log.enabledOutputs = [.file]
        
        var request = URLRequest(url: URL(string: "https://socials.sapoapps.vn/api/v3/pages/263252848906359,267855735091337,402801833528395,105809765495089/conversations")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Sapo/5.27.1/1260745 iPhone11,6/iOS 15.4.1", forHTTPHeaderField: "User-Agent")
        request.setValue("0000000000000000000003", forHTTPHeaderField: "Header-Field-3")
        request.setValue("0000000000000000000004", forHTTPHeaderField: "Header-Field-4")
        request.setValue("0000000000000000000005", forHTTPHeaderField: "Header-Field-5")
        request.setValue([Int.random(in: 100000000...999999999),
                          Int.random(in: 100000000...999999999),
                          Int.random(in: 100000000...999999999),
                          Int.random(in: 100000000...999999999),
                          Int.random(in: 100000000...999999999),
                          Int.random(in: 100000000...999999999)].map({ "\($0)" }).joined(separator: "."),
                         forHTTPHeaderField: "Very-Long-Token")

        for i in (0...20000).reversed() {
            log.logcURLRequest(request, prefix: "#\(i)")
        }
        
        print(LogManager.shared.filePath)
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
