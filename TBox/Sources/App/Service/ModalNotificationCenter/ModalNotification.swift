//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

struct ModalNotification {
    struct Name: Equatable {
        let rawValue: String
    }

    struct UserInfoKey: Equatable, Hashable {
        let rawValue: String
    }

    let id: UUID
    let name: Name
    let userInfo: [AnyHashable: Any]?
}

extension ModalNotification {
    var notification: Notification {
        Notification(name: name.notificationName, object: nil, userInfo: userInfo)
    }
}

extension ModalNotification.Name {
    var notificationName: Notification.Name { .init(rawValue) }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ name: Notification.Name) {
        rawValue = name.rawValue
    }
}
