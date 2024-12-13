//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ModalNotification: @unchecked Sendable {
    public struct Name: Equatable, Sendable {
        let rawValue: String
    }

    public struct UserInfoKey: Equatable, Hashable, Sendable {
        let rawValue: String
    }

    public let id: UUID
    public let name: Name
    public let userInfo: [AnyHashable: Any]?
}

extension ModalNotification {
    var notification: Notification {
        Notification(name: name.notificationName, object: nil, userInfo: userInfo)
    }
}

public extension ModalNotification.Name {
    internal var notificationName: Notification.Name { .init(rawValue) }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ name: Notification.Name) {
        rawValue = name.rawValue
    }
}

public extension ModalNotification.UserInfoKey {
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
