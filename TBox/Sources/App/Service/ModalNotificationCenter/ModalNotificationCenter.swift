//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

class ModalNotificationCenter {
    static let `default` = ModalNotificationCenter(notificationCenter: .default)
    static let modalId = "net.tasuwo.TBox.ModalNotificationCenter.userInfoKey.id"

    private let notificationCenter: NotificationCenter

    // MARK: - Initializer

    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Methods

    func post(id: UUID, name: ModalNotification.Name, userInfo: [ModalNotification.UserInfoKey: Any]? = nil) {
        var info: [AnyHashable: Any] = [:]
        info[Self.modalId] = id
        info.merge(userInfo ?? [:], uniquingKeysWith: { value, _ in value })
        notificationCenter.post(name: name.notificationName, object: nil, userInfo: info)
    }

    func publisher(for id: UUID, name: ModalNotification.Name) -> AnyPublisher<ModalNotification, Never> {
        notificationCenter.publisher(for: name.notificationName)
            .filter { $0.userInfo?[Self.modalId] as? UUID == id }
            .compactMap { notification in
                guard let id = notification.userInfo?[Self.modalId] as? UUID else { return nil }
                return ModalNotification(id: id, name: name, userInfo: notification.userInfo)
            }
            .eraseToAnyPublisher()
    }
}
