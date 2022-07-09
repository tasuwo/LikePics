//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation
import XCTest

@testable import Domain

class CloudAvailabilityTest: XCTestCase {
    func test_デコードできる() {
        let testCases: [(line: UInt, source: String, availability: CloudAvailability)] = [
            (#line, "{\"available\":\"none\"}", .available(.none)),
            (#line, "{\"available\":\"account_changed\"}", .available(.accountChanged)),
            (#line, "{\"unavailable\":true}", .unavailable)
        ]
        testCases.forEach { testCase in
            let decoder = JSONDecoder()
            let data = testCase.source.data(using: .utf8)!
            let decoded = try! decoder.decode(CloudAvailability.self, from: data)

            XCTAssertEqual(decoded, testCase.availability, line: testCase.line)
        }
    }

    func test_エンコードできる() {
        let testCases: [(line: UInt, availability: CloudAvailability, expected: String)] = [
            (#line, .available(.none), "{\"available\":\"none\"}"),
            (#line, .available(.accountChanged), "{\"available\":\"account_changed\"}"),
            (#line, .unavailable, "{\"unavailable\":true}")
        ]
        testCases.forEach { testCase in
            let encoder = JSONEncoder()
            let data = try! encoder.encode(testCase.availability)

            XCTAssertEqual(String(data: data, encoding: .utf8), testCase.expected, line: testCase.line)
        }
    }
}
