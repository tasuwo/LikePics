//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

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
    @objc dynamic var cloudUsageContextLastLoggedInCloudAccountId: String? {
        return self.string(forKey: UserSettingsStorage.Key.showHiddenItems.rawValue)
    }
}

extension CloudUsageContextStorage: CloudUsageContextStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var lastLoggedInCloudAccountId: AnyPublisher<String?, Never> {
        return self.userDefaults
            .publisher(for: \.cloudUsageContextLastLoggedInCloudAccountId)
            .eraseToAnyPublisher()
    }

    public func set(lastLoggedInCloudAccountId: String?) {
        self.queue.sync { self.setFetchLastLoggedInCloudAccountId(lastLoggedInCloudAccountId) }
    }
}
