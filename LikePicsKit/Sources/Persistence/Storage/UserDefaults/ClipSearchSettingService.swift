//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation

public class ClipSearchSettingService {
    enum Key: String {
        case setting = "clipSearchSetting"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.ClipSearchSettingService")

    // MARK: - Initializers

    public init() {}

    // MARK: - Methods

    private func setSettingNonAtomically(_ setting: ClipSearchSetting) {
        guard fetchSettingNonAtomically() != setting else { return }
        let data = try? JSONEncoder().encode(setting)
        userDefaults.setValue(data, forKey: Key.setting.rawValue)
    }

    private func fetchSettingNonAtomically() -> ClipSearchSetting? {
        guard let data = userDefaults.clipSearchSetting else { return nil }
        return try? JSONDecoder().decode(ClipSearchSetting.self, from: data)
    }
}

extension UserDefaults {
    @objc dynamic var clipSearchSetting: Data? {
        return self.object(forKey: ClipSearchSettingService.Key.setting.rawValue) as? Data
    }
}

extension ClipSearchSettingService: Domain.ClipSearchSettingService {
    // MARK: - Domain.ClipSearchSettingService

    public func save(_ setting: ClipSearchSetting) {
        queue.async { self.setSettingNonAtomically(setting) }
    }

    public func read() -> ClipSearchSetting? {
        return queue.sync { fetchSettingNonAtomically() }
    }

    public func query() -> AnyPublisher<ClipSearchSetting?, Never> {
        userDefaults
            .publisher(for: \.clipSearchSetting)
            .compactMap {
                guard let data = $0 else { return nil }
                return try? JSONDecoder().decode(ClipSearchSetting.self, from: data)
            }
            .eraseToAnyPublisher()
    }
}
