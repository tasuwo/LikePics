//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol UserSettingsObserver: AnyObject {
    func onUpdated(showHiddenItemsTo: Bool)
}

public protocol UserSettingStorageProtocol {
    func add(observer: UserSettingsObserver)
    func remove(observer: UserSettingsObserver)
    func set(showHiddenItems: Bool)
    func fetchShowHiddenItems() -> Bool
}
