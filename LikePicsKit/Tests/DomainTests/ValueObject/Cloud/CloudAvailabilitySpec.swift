//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation
import Nimble
import Quick

@testable import Domain

class CloudAvailabilitySpec: QuickSpec {
    override func spec() {
        describe("init(from:)") {
        }

        describe("encode(to:)") {
            ([
                .available(.none),
                .available(.accountChanged),
                .unavailable
            ] as [CloudAvailability]).forEach { availability in
                it("エンコードできる") {
                    let encoder = JSONEncoder()
                    let data = try! encoder.encode(availability)

                    let decoder = JSONDecoder()
                    let decoded = try! decoder.decode(CloudAvailability.self, from: data)

                    expect(decoded).to(equal(availability))
                }
            }
        }
    }
}
