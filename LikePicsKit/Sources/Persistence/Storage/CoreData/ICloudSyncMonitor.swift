//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreData

public class ICloudSyncMonitor {
    static let userInfoKey = NSPersistentCloudKitContainer.eventNotificationUserInfoKey

    private let logger: Loggable
    private var disposableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    public init(logger: Loggable) {
        self.logger = logger

        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let event = notification.userInfo?[Self.userInfoKey] as? NSPersistentCloudKitContainer.Event else { return }

                switch event.type {
                case .setup:
                    self.logger.write(ConsoleLog(level: .debug, message: """
                    Setup \(event.isStarted ? "started" : "ended")
                    """))

                case .import:
                    self.logger.write(ConsoleLog(level: .debug, message: """
                    Import \(event.isStarted ? "started" : "ended")
                    """))

                case .export:
                    self.logger.write(ConsoleLog(level: .debug, message: """
                    Export \(event.isStarted ? "started" : "ended")
                    """))

                @unknown default:
                    assertionFailure("Unknown NSPersistentCloudKitContainer.Event")
                }

                if let error = event.error {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Filed to iCloud sync. \(error.localizedDescription)
                    - type: \(event.type)
                    - startDate: \(event.startDate)
                    - endDate: \(String(describing: event.endDate))
                    """))
                }
            }
            .store(in: &self.disposableBag)
    }
}

extension NSPersistentCloudKitContainer.Event {
    var isStarted: Bool {
        return self.endDate == nil
    }
}
