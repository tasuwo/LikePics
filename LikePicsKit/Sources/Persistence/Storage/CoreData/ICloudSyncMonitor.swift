//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreData
import os.log

public class ICloudSyncMonitor {
    static let userInfoKey = NSPersistentCloudKitContainer.eventNotificationUserInfoKey

    private var disposableBag = Set<AnyCancellable>()
    private let logger = Logger(LogHandler.iCloudSync)

    // MARK: - Lifecycle

    public init() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let event = notification.userInfo?[Self.userInfoKey] as? NSPersistentCloudKitContainer.Event else { return }

                switch event.type {
                case .setup:
                    self.logger.debug("Setup \(event.isStarted ? "started" : "ended")")

                case .import:
                    self.logger.debug("Import \(event.isStarted ? "started" : "ended")")

                case .export:
                    self.logger.debug("Export \(event.isStarted ? "started" : "ended")")

                @unknown default:
                    assertionFailure("Unknown NSPersistentCloudKitContainer.Event")
                }

                if let error = event.error {
                    self.logger.error("Failed to iCloud sync: \(error.localizedDescription, privacy: .public)")
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
