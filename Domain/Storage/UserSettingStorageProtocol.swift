//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol UserSettingStorageProtocol {
    func set(showHiddenItems: Bool)
    func fetchShowHiddenItems() -> Bool
}
