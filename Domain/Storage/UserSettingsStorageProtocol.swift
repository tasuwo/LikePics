//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct UserSettings {
    public let showHiddenItems: Bool

    // MARK: - Lifecycle

    public init(showHiddenItems: Bool) {
        self.showHiddenItems = showHiddenItems
    }
}

public protocol UserSettingsObserver: AnyObject {
    func onUpdated(to: UserSettings)
}

public protocol UserSettingsStorageProtocol {
    func add(observer: UserSettingsObserver)
    func remove(observer: UserSettingsObserver)
    func set(showHiddenItems: Bool)
    func fetch() -> UserSettings
}