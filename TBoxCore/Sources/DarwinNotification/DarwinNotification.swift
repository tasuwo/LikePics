//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct DarwinNotification: Equatable {
    public struct Name: Equatable {
        let rawValue: CFString
    }

    let name: Name
}

extension DarwinNotification.Name {
    public init(_ rawValue: String) {
        self.rawValue = rawValue as CFString
    }

    init(_ cfNotificationName: CFNotificationName) {
        rawValue = cfNotificationName.rawValue
    }
}
