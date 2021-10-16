//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation

public class CloudUsageContextStorage {
    enum Key: String {
        case lastLoggedInCloudAccountId = "cloudUsageContextLastLoggedInCloudAccountId"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.UserSettingStorage")

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    private func setFetchLastLoggedInCloudAccountId(_ lastLoggedInCloudAccountId: String?) {
        guard self.fetchLastLoggedInCloudAccountId() != lastLoggedInCloudAccountId else { return }
        self.userDefaults.set(lastLoggedInCloudAccountId, forKey: Key.lastLoggedInCloudAccountId.rawValue)
    }

    private func fetchLastLoggedInCloudAccountId() -> String? {
        return self.userDefaults.cloudUsageContextLastLoggedInCloudAccountId
    }
}

extension UserDefaults {
    // swiftlint:disable:next identifier_name
    @objc dynamic var cloudUsageContextLastLoggedInCloudAccountId: String? {
        return self.string(forKey: CloudUsageContextStorage.Key.lastLoggedInCloudAccountId.rawValue)
    }
}

extension CloudUsageContextStorage: CloudUsageContextStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var lastLoggedInCloudAccountId: String? {
        return self.userDefaults.cloudUsageContextLastLoggedInCloudAccountId
    }

    public func set(lastLoggedInCloudAccountId: String?) {
        self.queue.sync { self.setFetchLastLoggedInCloudAccountId(lastLoggedInCloudAccountId) }
    }
}
